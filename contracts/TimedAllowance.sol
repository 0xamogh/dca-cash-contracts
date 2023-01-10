// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TimedAllowance is Ownable {
    using SafeERC20 for IERC20;

    struct ApprovalInfo {
        uint256 amount;
        uint256 resetTime;
        uint256 lastReset;
    }
            // from            // to              //tokenIn          //tokenOut
    mapping(address => mapping(address => mapping(address => mapping(address => ApprovalInfo)))) public orderAllowances;

    function approve(address to, address tokenIn, address tokenOut, uint256 amount, uint256 resetTime) public {
        console.log(tx.origin, address(this));
        require(IERC20(tokenIn).allowance(tx.origin, address(this)) > 0, "TimedAllowance : Please approve ERC20 first");
        
        // using tx origin ensures that nobody apart from the actual signer can modify their orderAllowances
        orderAllowances[tx.origin][to][tokenIn][tokenOut] = ApprovalInfo({
            amount : amount,
            resetTime: resetTime,
            lastReset : 0
        });
    }

    function transferFrom(address from, address to, address tokenIn,address tokenOut, uint256 amount) public onlyOwner {
        require(orderAllowances[from][to][tokenIn][tokenOut].amount > 0,"TimedAllowance : Amount not set");
        require(block.timestamp - orderAllowances[from][to][tokenIn][tokenOut].lastReset >= orderAllowances[from][to][tokenIn][tokenOut].resetTime,"TimedAllowance : Reset time has not elapsed yet, try again later");
        require(orderAllowances[from][to][tokenIn][tokenOut].amount >= amount,"TimedAllowance : Not enough allowance");

        orderAllowances[from][to][tokenIn][tokenOut].lastReset = block.timestamp;
        IERC20(tokenIn).safeTransferFrom(from, to, amount);
    }

    function removeApproval(address to, address tokenIn, address tokenOut) public {
        approve(to, tokenIn, tokenOut, 0, type(uint256).max);
    }
}