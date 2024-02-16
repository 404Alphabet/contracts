// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ITokenBlacklist {
    function checkToken(address _token) external view;
}
