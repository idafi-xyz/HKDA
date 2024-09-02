// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NativeCurrencyPaymentFallback - A contract that has a fallback to accept native currency payments.
 */
abstract contract NativeCurrencyPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /**
     * @notice Receive function accepts native currency transactions.
     * @dev Emits an event with sender and received value.
     */
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}