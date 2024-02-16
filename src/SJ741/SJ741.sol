//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISJ741} from "./interfaces/ISJ741.sol";
import {IERC721TokenReceiver} from "./interfaces/IERC721TokenReceiver.sol";
import {SJ20} from "./libraries/SJ20.sol";
import {SJ721} from "./libraries/SJ721.sol";

abstract contract SJ741 is ISJ741 {
  string public baseURI;
  string internal _name;
  string internal _symbol;

  uint256 internal constant _decimals = 8;
  uint256 internal constant _totalIds = 8888;
  uint256 internal constant _totalSupply = _totalIds * (10 ** _decimals);
  uint256 internal constant ONE = 10 ** _decimals; // 1 token
  uint256 internal constant MAX_ID = ONE + _totalIds;

  uint32 public minted; // Unique id mints
  uint32[] private broken; // NFTs that are broken

  address public dev;
  bool public supportsNFTInterface;

  mapping(address => mapping(address => bool)) private _operatorApprovals;
  mapping(address => mapping(address => uint)) internal _allowance;
  mapping(uint256 tokenId => address) public ownerOf;
  mapping(uint256 => address) private _nftApprovals;
  mapping(address => uint) internal _balanceOf;
  mapping(address => uint32[]) public ownedNFTs;
  mapping(uint32 => uint256) private idToIndex; 

  error UnsupportedReceiver();

  modifier onlyDev() {
    require(msg.sender == dev, "SJ741: Only dev");
    _;
  }

  constructor(string memory name_, string memory symbol_, string memory baseURI_) {
    _name = name_;
    _symbol = symbol_;
    baseURI = baseURI_;

    minted = uint32(ONE);
    _balanceOf[msg.sender] = _totalSupply;
    dev = msg.sender;
  }

  function name() public view virtual returns (string memory) { return _name; }
  function symbol() public view virtual returns (string memory) { return _symbol; }
  function decimals() public view virtual returns (uint) { return _decimals; }
  function totalSupply() public pure override returns (uint) { return _totalSupply; }
  function balanceOf( address account) public view override returns (uint) { return _balanceOf[account]; }
  function allowance(address owner, address spender) public view override returns (uint) { return _allowance[owner][spender]; }
  function setBaseURI(string memory newBaseURI) public onlyDev {baseURI = newBaseURI;}
  function changeDev(address newDev) public onlyDev {dev = newDev;} // Simple function to change developer address, or revoke ownership (with address(0))
  function toggleNFTinterface() public onlyDev {supportsNFTInterface = !supportsNFTInterface;}

function approve(address spender, uint amount) public override returns (bool) {

        // if the amount is greater than one token, and within range of IDs for NFTs 
        // then set NFT approval for the given ID
        if(amount > ONE && amount <= MAX_ID) {
            address owner = ownerOf[amount]; // getting the owner of token ID via the `amount` input
            if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert("SJ741: You are not approved");
            _nftApprovals[amount] = spender; // calling nft approval for the token and spender
            SJ721.emitApproval(owner, spender, amount);
            return true;
        }
        
        // else set the ERC20 allowance
        // the NFT ID range being set within a limited subset of ONE token(s)
        // allows for non-clashing interactions
        _allowance[msg.sender][spender] = amount;
        SJ20.emitApproval(msg.sender, spender, amount);
        return true;
    }

    function _transfer741(address from, address to, uint amount) internal virtual {
        
        require(_balanceOf[from] >= amount, "SJ741: transfer amount exceeds balance");
        
        // checking the decimal amount of tokens owned before transaction for both participants
        uint256 fromDecimalsPre = _balanceOf[from] % ONE;
        uint256 toDecimalsPre = _balanceOf[to] % ONE;
        
        // simple erc20 balance operations
        _transfer20(from, to, amount);

        // checking the decimal amount of tokens after transaction for both partcipants
        uint256 fromDecimalsPost = _balanceOf[from] % ONE;
        uint256 toDecimalsPost = _balanceOf[to] % ONE;

        // stores the NFT IDs owned by `from`, enabling NFT management for that address.
        uint32[] storage ownedNFTsArray = ownedNFTs[from];

        // references NFTs marked as "broken", tracking these special state NFTs.
        uint32[] storage brokenIDsArray = broken;

        // if sender has higher decimal count after transaction, then they "roll under" and break an NFT
        if (fromDecimalsPre < fromDecimalsPost) {

            if(ownedNFTsArray.length > 0) { // if the sender has an nft to send

                uint32 tokenId = ownedNFTsArray[0];//selects the user's first NFT from the list

                brokenIDsArray.push(tokenId);//pushes the nft into the "broken list" for limbo NFTs
                _transfer721(from, address(0), tokenId);//transfers the NFT ID ownership to (0) address for stewardship
            }
        }

        // if receiver has lower decimal count after transaction then they "roll over" and will "remake" an nft 
        if (toDecimalsPre > toDecimalsPost) {

            if(brokenIDsArray.length > 0) { // recover an id from broken list

                _transfer721(address(0), to, brokenIDsArray[brokenIDsArray.length - 1]);
                brokenIDsArray.pop();
            }
            else { // mint new id
                _mint(to);
            }
            
        }
        
        // amount of tokens - amount of whole tokens being processed in int
        uint amountInTokens = amount / ONE;

        // ignore minting nfts from dev when they call -- this allows for gas-efficient team operations
        // @DEV if dev gathers NFTs, use the ERC721 transferFrom method to extract
        // @DEV be careful, don't let the wallet fall to some convoluted transferFrom scam to do something unexpected
        if(from == dev) return;


        if(amountInTokens > 0) {

            uint len = ownedNFTsArray.length; //len is the length, or number of NFTs in the addresses's owned array
            len = amountInTokens < len ? amountInTokens : len;
            // transfers owned NFTs from `from` to `to` until either all are transferred or the desired amount is reached
            // Subtracts transferred NFT count from `amountInTokens` to update remaining transfers
            for (uint i = 0; i < len; i++) {
                _transfer721(from, to, ownedNFTsArray[0]); 
            }
            amountInTokens -= len;
            len = brokenIDsArray.length;
            len = amountInTokens < len ? amountInTokens : len;
            
            // recovers NFTs from the broken state to `to`, or mints new ones if not enough broken NFTs are available
            // if any tokens remain to be allocated, it mints new NFTs to `to` for the remaining balance
            for (uint i = 0; i < len; i++) {        
                _transfer721(address(0), to, brokenIDsArray[brokenIDsArray.length - 1]);
                brokenIDsArray.pop();
            }

            _mintBatch(to, amountInTokens - len);

        }
    }

    function _mintBatch(address to, uint256 amount) internal {
        if(amount == 0) return; // Exit if no NFTs to mint

        if(amount == 1) { // Optimize single mint process
            _mint(to);
            return;
        }
        uint32 id = minted; // Start ID from last minted value
        uint256 ownedLen = ownedNFTs[to].length; // Current number of NFTs owned by 'to'
        for(uint i = 0; i < amount;) {
            unchecked {
                id++; // Increment ID for each new NFT
            }
            ownerOf[id] = to; // Assign new NFT to owner.
            idToIndex[id] = ownedLen; // Map NFT ID to its index in owner's array
            ownedNFTs[to].push(id); // Add new NFT ID to owner's list

            SJ721.emitTransfer(address(0), to, id); // Emit NFT transfer event

            unchecked {
                ownedLen++; // Increment count of owned NFTs
                i++; // Move to next NFT
            }
        }
        unchecked {
            minted += uint32(amount); // Update total minted count
        }
    }


    function _mint(address to) internal returns(uint32 tokenId){
        unchecked {
            minted++; // Increment the total number of minted tokens
        }
        tokenId = minted; // Assign the newly minted token ID

        ownerOf[tokenId] = to; // Set ownership of the new token to 'to'
        idToIndex[tokenId] = ownedNFTs[to].length; // Map the new token ID to its index in the owner's list
        ownedNFTs[to].push(tokenId); // Add the new token ID to the owner's list of owned tokens
        
        SJ721.emitTransfer(address(0), to, tokenId); // Emit an event for the token transfer
    }


    // Updates the mappings and arrays managing ownership and index of NFTs after a transfer
    function _updateOwnedNFTs(address from, address to, uint32 tokenId) internal { 
        uint256 index = idToIndex[tokenId]; // Get current index of the token in the owner's list
        uint32[] storage nftArray = ownedNFTs[from]; // Reference to the list of NFTs owned by 'from'
        uint256 len = nftArray.length; // Current number of NFTs owned by 'from'
        uint32 lastTokenId = nftArray[len - 1]; // Last token in the 'from' array to swap with transferred token
        
        nftArray[index] = lastTokenId; // Replace the transferred token with the last token in the array
        nftArray.pop(); // Remove the last element, effectively deleting the transferred token from 'from'
        
        if(len - 1 != 0){ 
            idToIndex[lastTokenId] = index; // Update the index of the swapped token
        } 
    
        ownedNFTs[to].push(tokenId); // Add the transferred token to the 'to' array
        idToIndex[tokenId] = ownedNFTs[to].length - 1; // Update the index mapping for the transferred token
    }

    // Executes a simple ERC20 token transfer.
    function _transfer20(address from, address to, uint256 amount) internal {
        _balanceOf[from] -= amount; // Deduct the amount from the sender's balance
        unchecked {
            _balanceOf[to] += amount; // Add the amount to the recipient's balance
        }
        SJ20.emitTransfer(from, to, amount); // Emit an ERC20 transfer event
    }

    // Handles the transfer of an ERC721 token, ensuring proper ownership and event emission
    function _transfer721(address from, address to, uint32 tokenId) internal virtual {
        require(from == ownerOf[tokenId], "SJ741: Incorrect owner"); // Ensure 'from' is the current owner
        
        delete _nftApprovals[tokenId]; // Clear any approvals for this token
        ownerOf[tokenId] = to; // Transfer ownership of the token to 'to'
        _updateOwnedNFTs(from, to, tokenId); // Update ownership tracking structures
        SJ721.emitTransfer(from, to, tokenId); // Emit an ERC721 transfer event
    }


    // only erc20 calls this
    // if amount is a token id owned my the caller send as an NFT
    // else transfer741
    function transfer(address to, uint amount) public override returns (bool) {
        if(ownerOf[amount] == msg.sender) {
            _transfer721(msg.sender, to, uint32(amount));
            _transfer20(msg.sender, to, ONE);
            return true;
        }
        _transfer741(msg.sender, to, amount);
        return true;
    }

    // erc20 and erc721 call this
    function transferFrom(address from, address to, uint amount) public override returns (bool) {

        //if amount is within the NFT id range, then a simple NFT transfer + token amount (ONE)
        if(amount > ONE && amount <= MAX_ID) {
            require(
                //require from is the msg caller, or that caller is approved for that specific NFT, or all NFTs 
                msg.sender == from || msg.sender == getApproved(amount) || isApprovedForAll(from, msg.sender),
                "SJ741: You don't have the right"
                );

            _transfer721(from, to, uint32(amount));
            _transfer20(from, to, ONE);
            return true;
        }

        _spendAllowance(from, msg.sender, amount);
        _transfer741(from, to, amount);
        return true;

    }

    // erc721
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        require(
                msg.sender == from || msg.sender == getApproved(tokenId) || isApprovedForAll(from, msg.sender),
                "SJ741: You don't have the right"
            );
        _transfer721(from, to, uint32(tokenId)); 
        _transfer20(from, to, ONE);

        if (
            to.code.length != 0 &&
            IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, "") !=
            IERC721TokenReceiver.onERC721Received.selector
        ) {
            revert UnsupportedReceiver();
        }
    }

    // erc721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        require(
                msg.sender == from || msg.sender == getApproved(tokenId) || isApprovedForAll(from, msg.sender),
                "SJ741: You don't have the right"
            );
        _transfer721(from, to, uint32(tokenId)); 
        _transfer20(from, to, ONE);

        if (
            to.code.length != 0 &&
            IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) !=
            IERC721TokenReceiver.onERC721Received.selector
        ) {
            revert UnsupportedReceiver();
        }
    }

    function _spendAllowance(address owner, address spender, uint amount) internal virtual {
        require(_allowance[owner][spender] >= amount, "SJ741: insufficient allowance");
        _allowance[owner][spender] -= amount;
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (ownerOf[tokenId] == address(0)) revert();
        return _nftApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        SJ721.emitApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(tokenId <= MAX_ID, "SJ741: Invalid id");
        if (bytes(baseURI).length == 0) {return "";}
        return string(abi.encodePacked(baseURI, toString(tokenId - ONE), ".json"));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";} uint256 temp = value; uint256 digits;
        while (temp != 0) {digits++; temp /= 10;} bytes memory buffer = new bytes(digits);
        while (value != 0) {digits -= 1; buffer[digits] = bytes1(uint8(value % 10) + 48); value /= 10;}
        return string(buffer);
    }

    function withdraw() external onlyDev {
        payable(dev).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            // Even though we support ERC721 and should return true, etherscan wants to treat us as ERC721 instead of ERC20
            // @DEV ERC165 for ERC721 can be toggled on for reasons of frontend/dapp/script implementations, but is very specific
            (supportsNFTInterface && interfaceId == 0x80ac58cd) || // ERC165 interface ID for ERC721
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165
            interfaceId == 0x36372b07;   // ERC165 interface ID for ERC20
    }
}