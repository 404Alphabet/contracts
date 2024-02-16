// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IAdmin {
    function userIsAdmin(address _user) external view returns (bool);
}
