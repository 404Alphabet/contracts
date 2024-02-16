// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IUnlockCondition} from "../interfaces/IUnlockCondition.sol";
import {FullMath} from "../math/FullMath.sol";

library VestingMathLibrary {
  function getWithdrawableAmount(uint256 _startEmission, uint256 _endEmission,uint256 _amount, uint256 _timestamp, address _condition) internal view returns (uint256){

    if (_condition != address(0) && IUnlockCondition(_condition).unlockTokens()) {
      return _amount;
    }

    if(_startEmission == 0 || _timestamp < _startEmission) {
      return _endEmission < _timestamp ? _amount : 0;
    }

    uint256 timeClamp = _timestamp;

    if(timeClamp > _endEmission) {
      timeClamp = _endEmission;
    }

    if (timeClamp < _startEmission) {
      timeClamp = _startEmission;
    }

    uint256 timePassed = timeClamp - _startEmission;
    uint256 fullPeriod = _endEmission - _startEmission;
    return FullMath.mulDiv(_amount, timePassed, fullPeriod);
  }
}