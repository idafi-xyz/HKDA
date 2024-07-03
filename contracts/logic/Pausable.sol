// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev When the contract is Paused, all methods cannot be used.
 */
abstract contract Pausable is Context {
    event Pause();
    event Unpause();

    bool internal _paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Permission control must be implemented in the final contract.
     */
    function pause() public virtual;

    /**
     * @dev Permission control must be implemented in the final contract.
     */
    function unpause() public virtual;

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function _pause() internal virtual {
        _paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function _unpause() internal virtual {
        _paused = false;
        emit Unpause();
    }

    /**
     * @dev Returns the paused status of the token.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }
}
