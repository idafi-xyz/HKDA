// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Permissions.sol";

abstract contract Whitelistable is Permissions {
    mapping(address => bool) internal _whitelistAccounts;
    bool internal _whitelistedStatus;

    event Whitelisted(address indexed _account);
    event UnWhitelisted(address indexed _account);
    event ChangeWhitelistedStatus(bool _status);

    /**
     * @dev Throws if argument account is blacklisted.
     * @param _account The address to check.
     */
    modifier whenWhitelisted(address _account) {
        require(
            !_whitelistedStatus || _isWhitelisted(_account),
            "Whitelistable: account not is whitelisted"
        );
        _;
    }

    /**
     * @notice Checks if account is whitelisted.
     * @param _account The address to check.
     * @return True if the account is whitelisted, false if the account is not whitelisted.
     */
    function isWhitelisted(
        address _account
    ) external view returns (bool) {
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
     * @notice Adds account to whitelist.
     * @param _account The address to whitelist.
     */
    function whitelist(address _account) external virtual whenNotPaused OnlyCompliance {
        _whitelistAccounts[_account] = true;
        emit Whitelisted(_account);
    }

    function _whitelist(address _account) internal {
        _whitelistAccounts[_account] = true;
    }

    /**
     * @notice Removes account from whitelist.
     * @param _account The address to remove from the whitelist.
     */
    function unWhitelist(
        address _account
    ) external virtual whenNotPaused OnlyCompliance {
        _whitelistAccounts[_account] = false;
        emit UnWhitelisted(_account);
    }

    /**
     * @dev Disable whitelist
     */
    function disableWhitelisted() external virtual whenNotPaused OnlyCompliance {
        _whitelistedStatus = false;
        emit ChangeWhitelistedStatus(false);
    }

    /**
     * @dev Enable whitelist
     */
    function enableWhitelisted() external virtual whenNotPaused OnlyCompliance {
        _enableWhitelisted();
        emit ChangeWhitelistedStatus(true);
    }

    function _enableWhitelisted() internal {
        _whitelistedStatus = true;
    }

    /**
     * @dev Helper methods for whitelisted status.
     */
    function whitelistedStatus() public view returns (bool) {
        return _whitelistedStatus;
    }
}
