//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SJ20 {
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function emitTransfer(address _from, address _to, uint _amount) internal { emit Transfer(_from, _to, _amount); }
    function emitApproval(address _owner, address _spender, uint _value) internal { emit Approval(_owner, _spender, _value); }
}