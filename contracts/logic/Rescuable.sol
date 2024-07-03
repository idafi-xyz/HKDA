// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Permissions.sol";

abstract contract Rescuable is Permissions {
    using SafeERC20 for IERC20;

    event RescueERC20(
        address indexed tokenContract,
        address indexed to,
        uint256 amount
    );
    event RescueNativeCurrency(address indexed to, uint256 value);

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param tokenContract ERC20 token contract address
     * @param to        Recipient address
     * @param amount    Amount to withdraw
     */
    function rescueERC20(
        IERC20 tokenContract,
        address to,
        uint256 amount
    ) external virtual whenNotPaused OnlyCompliance {
        tokenContract.safeTransfer(to, amount);
        emit RescueERC20(address(tokenContract), to, amount);
    }

    /**
     * @notice Rescue Native Currency locked up in this contract.
     * @param to Recipient address
     * @param value value to withdraw
     */
    function rescueNativeCurrency(
        address to,
        uint256 value
    ) external virtual whenNotPaused OnlyCompliance {
        payable(to).transfer(value);
        emit RescueNativeCurrency(to, value);
    }
}
