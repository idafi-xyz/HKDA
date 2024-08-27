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
     * @notice called by the owner to pause, triggers stopped state.
     */
    function pause() external virtual;

    /**
     * @dev Permission control must be implemented in the final contract.
     * @notice called by the owner to unpause, triggers stopped state.
     */
    function unpause() external virtual;

    /**
     * @dev Helper methods for pause.
     */
    function _pause() internal virtual {
        _paused = true;
        emit Pause();
    }

   /**
     * @dev Helper methods for unpause.
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
