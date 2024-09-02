// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract AbstractStablecoinTokenV1 is IERC20, IERC20Metadata {
    function mint(address to, uint256 amount) external virtual returns (bool);

    function burn(uint256 amount) external virtual;

    function seizeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual returns (bool);
}
