// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Freezable {
    mapping(address => bool) internal _frozenList;

    event Freeze(address indexed _account);
    event UnFreeze(address indexed _account);

    /**
     * @notice Checks if account is frozen.
     * @param _account The address to check.
     * @return True if the account is frozen, false if the account is not frozen.
     */
    function isFrozen(
        address _account
    ) external view virtual returns (bool) {
        return _isFrozen(_account);
    }

    /**
     * @dev Permission control must be implemented in the final contract.
     * @notice Adds account to frozen list.
     * @param _account The address to frozen list.
     */
    function freeze(address _account) external virtual ;

    /**
     * @dev Helper methods for freeze.
     */
    function _freeze(address _account) internal virtual {
        _frozenList[_account] = true;
        emit Freeze(_account);
    }

    /**
     * @dev Permission control must be implemented in the final contract.
     * @notice Removes account from frozen list.
     * @param _account The address to remove from the frozen list.
     */
    function unFreeze(address _account) external virtual ;

    /**
     * @dev Helper methods for unFreeze.
     */
    function _unFreeze(address _account) internal virtual {
        _frozenList[_account] = false;
        emit UnFreeze(_account);
    }

    /**
     * @dev Checks if account is frozen.
     * @param _account The address to check.
     * @return true if the account is frozen, false otherwise.
     */
    function _isFrozen(address _account) internal view virtual returns (bool) {
        return _frozenList[_account];
    }
}
