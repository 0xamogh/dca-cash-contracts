// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TimedAllowance.sol";
import "./lib/LibERC20Token.sol";
import "./lib/Types.sol";
import "./lib/OpsTaskCreator.sol";
import "hardhat/console.sol";

contract DcaCash is Ownable, OpsTaskCreator {

    using LibERC20Token for IERC20;
    using FullMath for uint256;

    IUniswapV3Factory public constant factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    // address public MATIC_ADDRESS = 0x0000000000000000000000000000000000001010;
    TimedAllowance public timedAllowance;

    mapping(bytes32 => address) taskIdOwners;    
    uint24 public constant poolFee = 500;
    uint256 public gasDeposit;
    uint256 public recurringFee;

    constructor(address automate) OpsTaskCreator(automate, _msgSender()){
        timedAllowance = new TimedAllowance();
        
        //10 MATIC
        gasDeposit = 10000000000000000000;
        recurringFee = 0;
    }

    function executeSwap(address user, address tokenIn, address tokenOut, uint256 amountIn) external onlyDedicatedMsgSender returns (uint256 amountOut) {

        // Transfer tokens in from user
        timedAllowance.transferFrom(user, address(this), tokenIn, tokenOut, amountIn);

        // Pay dev x%
        if(recurringFee > 0){
            payDevFee(tokenIn, amountIn.mulDiv(recurringFee,1000));
        }

        // Get UniV3 pool address
        address pool = factory.getPool(tokenIn, tokenOut, poolFee);

        // LibERC20Token (approve if below)
        LibERC20Token.approveIfBelow(tokenIn, address(swapRouter), amountIn);
        
        // Allow for 5% slippage
        uint256 quote = FullMath.mulDiv(getQuote(pool, amountIn, tokenIn, tokenOut), 95, 100);

        // Create swap data
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: user,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: quote,
                sqrtPriceLimitX96: 0
            });

        // Execute swap
        amountOut = swapRouter.exactInputSingle(params);
    }

    function getQuote(address pool, uint256 amountIn, address tokenIn, address tokenOut) public view returns (uint256 quote) {
        // using default value of 10 seconds for UniV3 TWAPs
        (int24 arithmaticMeanTick,) = OracleLibrary.consult(pool, 10);
        quote = OracleLibrary.getQuoteAtTick(arithmaticMeanTick, uint128(amountIn), tokenIn, tokenOut);
    }

    function createTask(address tokenIn, address tokenOut, uint256 amount, uint256 resetTime) public payable returns (bytes32){
        
        timedAllowance.approve(address(this), tokenIn, tokenOut, amount, resetTime);
        (uint256 readAmount,,) = timedAllowance.orderAllowances(tx.origin,address(this),tokenIn,tokenOut);
        require( readAmount > 0 && readAmount == amount, "DcaCash : Please set a valid amount");

        _depositFunds(gasDeposit, ETH);

        bytes memory execData = abi.encodeWithSelector(this.executeSwap.selector,_msgSender(), tokenIn, tokenOut, amount);
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });
        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _timeModuleArg(block.timestamp, resetTime + 1);
        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(
            address(this),
            execData,
            moduleData,
            address(0)
        );

        taskIdOwners[id] = _msgSender();
        return id;
    }

    function cancelTask(bytes32 id) external {
        require(taskIdOwners[id] == _msgSender(),"DcaCash : You do not own this task");
        _cancelTask(id);
    }

    function setGasDeposit(uint256 amount) external onlyOwner {
        gasDeposit = amount;
    }

    function setRecurringFee(uint256 amount) external onlyOwner {
        recurringFee = amount;
    }

    function payDevFee(address token, uint256 amount) public {
        IERC20(token).transfer(owner(), amount);
    }
}