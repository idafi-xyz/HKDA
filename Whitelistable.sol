// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Whitelistable {
    mapping(address => bool) internal _whitelistAccounts;
    bool internal _whitelistedStatus;

    event Whitelisted(address indexed _account);
    event UnWhitelisted(address indexed _account);
    event ChangeWhitelistedStatus(bool _status);

    /**
     * @notice Checks if account is whitelisted.
     * @param _account The address to check.
     * @return True if the account is whitelisted, false if the account is not whitelisted.
     */
    function isWhitelisted(address _account) external view returns (bool) {
        return _isWhitelisted(_account);
    }

    /**
     * @dev Checks if account is whitelisted.
     * @param _account The address to check.
     * @return true if the account is whitelisted, false otherwise.
     */
    function _isWhitelisted(address _account) internal view returns (bool) {
        return _whitelistAccounts[_account];
    }

    /**
     * @dev Permission control must be implemented in the final contract.
     * @notice Adds account to whitelist.
     * @param _account The address to whitelist.
     */
    function whitelist(address _account) external virtual;

    /**
     * @dev Helper methods for whitelist.
     */
    function _whitelist(address _account) internal virtual {
        _whitelistAccounts[_account] = true;
        emit Whitelisted(_account);
    }

    /**
     * @dev Permission control must be implemented in the final contract.
     * @notice Removes account from whitelist.
     * @param _account The address to remove from the whitelist.
     */
    function unWhitelist(address _account) external virtual;

    /**
     * @dev Helper methods for unWhitelist.
     */
    function _unWhitelist(address _account) internal virtual {
        _whitelistAccounts[_account] = false;
        emit UnWhitelisted(_account);
    }

    /**
     * @dev Permission control must be implemented in the final contract.
     * @notice Disable whitelist
     */
    function disableWhitelisted() external virtual;

    /**
     * @dev Helper methods for Disable whitelist.
     */
    function _disableWhitelisted() internal virtual {
        _whitelistedStatus = false;
        emit ChangeWhitelistedStatus(false);
    }

    /**
     * @dev Permission control must be implemented in the final contract.
     * @notice Enable whitelist
     */
    function enableWhitelisted() external virtual;

    /**
     * @dev Helper methods for Enable whitelist.
     */
    function _enableWhitelisted() internal virtual {
        _whitelistedStatus = true;
        emit ChangeWhitelistedStatus(true);
    }

    /**
     * @dev Helper methods for whitelisted status.
     */
    function whitelistedStatus() public view returns (bool) {
        return _whitelistedStatus;
    }
}
