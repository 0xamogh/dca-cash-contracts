// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title LibERC20Token
/// @notice Utility function for ERC20 tokens
library LibERC20Token {
    using SafeERC20 for IERC20;

    /// @param token Token to approve
    /// @param spender Address of wallet to approve spending for
    /// @param amount Amount of token to approve
    function approveIfBelow(address token, address spender, uint256 amount) internal {
        uint256 currentAllowance = IERC20(token).allowance(address(this), spender);

        if (amount > currentAllowance) {
            // Some tokens (like USDT) do not work when changing the allowance from an existing
            // non-zero allowance value. They must first be approved by zero and then changed
            // to the actual allowance.
            if (currentAllowance > 0) IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }
}
