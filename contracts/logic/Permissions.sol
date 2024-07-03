// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pausable.sol";

abstract contract Permissions is Pausable {
    address internal _compliance;
    address internal _operator;

    event ComplianceChanged(address indexed newAddress);
    event OperatorChanged(address indexed newAddress);

    /**
     * @dev throws if called by any account other than the compliance.
     */
    modifier OnlyCompliance() {
        require(
            _msgSender() == _compliance,
            "Permissions: Only compliance team call this method"
        );
        _;
    }

    /**
     * @dev throws if called by any account other than the operator.
     */
    modifier OnlyOperator() {
        require(
            _msgSender() == _operator,
            "Permissions: Only operator team call this method"
        );
        _;
    }

    modifier OnlyComplianceOrOperator() {
        require(
            _msgSender() == _compliance || _msgSender() == _operator,
            "Permissions: Only compliance team or operator team call this method"
        );
        _;
    }

    /**
     * @notice Updates the compliance address.
     * @param _newAddress The address of the new compliance.
     */
    function updateCompliance(
        address _newAddress
    ) external virtual whenNotPaused OnlyCompliance {
        _updateCompliance(_newAddress);
        emit ComplianceChanged(_newAddress);
    }

    function _updateCompliance(address _newAddress) internal {
        require(
            _newAddress != address(0),
            "Permissions: new compliance is the zero address"
        );
        _compliance = _newAddress;
    }

    function compliance() public view virtual returns (address) {
        return _compliance;
    }

    /**
     * @notice Updates the operator address.
     * @param _newAddress The address of the new operator.
     */
    function updateOperator(
        address _newAddress
    ) external virtual whenNotPaused OnlyOperator {
        _updateOperator(_newAddress);
        emit OperatorChanged(_newAddress);
    }

    function _updateOperator(address _newAddress) internal virtual {
        require(
            _newAddress != address(0),
            "Permissions: new operator is the zero address"
        );
        _operator = _newAddress;
    }

    function operator() public view virtual returns (address) {
        return _operator;
    }
}
