//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {IERC721} from "./IERC721.sol";

interface ISJ741 is IERC20, IERC721 {
function balanceOf(address account) external override(IERC20, IERC721) view returns (uint256);
    function approve(address spender, uint256 value) external override(IERC20, IERC721) returns (bool);
    function transferFrom(address from, address to, uint256 value) external override(IERC20, IERC721) returns (bool);
}