// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract Rescuable {
    using SafeERC20 for IERC20;

    event RescueERC20(
        address indexed tokenContract,
        address indexed to,
        uint256 amount
    );
    event RescueNativeCurrency(address indexed to, uint256 value);

    /**
     * @dev Permission control must be implemented in the final contract.
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param tokenContract ERC20 token contract address
     * @param to        Recipient address
     * @param amount    Amount to withdraw
     */
    function rescueERC20(
        IERC20 tokenContract,
        address to,
        uint256 amount
    ) external virtual;

    /**
     * @dev Helper methods for rescue ERC20.
     */
    function _rescueERC20(
        IERC20 tokenContract,
        address to,
        uint256 amount
    ) internal virtual {
        tokenContract.safeTransfer(to, amount);
        emit RescueERC20(address(tokenContract), to, amount);
    }

    /**
     * @notice Rescue Native Currency locked up in this contract.
     * @param to Recipient address
     * @param value value to withdraw
     */
    function rescueNativeCurrency(address to, uint256 value) external virtual;

    /**
     * @dev Helper methods for rescue NativeCurrency.
     */
    function _rescueNativeCurrency(address to, uint256 value) internal virtual {
        require(to !=address(0),"Rescuable: transfer to the zero address");
        Address.sendValue(payable(to), value);
        emit RescueNativeCurrency(to, value);
    }
}
