// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IUnlockCondition {
    function unlockTokens() external view returns (bool);
}