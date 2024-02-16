//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SJ721 {
    event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function emitTransfer(address _from, address _to, uint _tokenId) internal { emit Transfer(_from, _to, _tokenId); }
    function emitApproval(address _owner, address _approve, uint _tokenId) internal { emit Approval(_owner, _approve, _tokenId); }
    function emitApprovalForAll(address _owner, address _operator, bool _approved) internal { emit ApprovalForAll(_owner, _operator, _approved); }
}