// SPDX-License-Identifier: GPL-3.0

import {FullMath} from "./math/FullMath.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {VestingMathLibrary} from "./libraries/VestingMathLibrary.sol";

// Interfaces
import {IAdmin} from "./interfaces/IAdmin.sol";
import {IMigrator} from "./interfaces/IMigrator.sol";
import {ITokenBlacklist} from "./interfaces/ITokenBlacklist.sol";

// This token vesting contract will handle ERC-20 and ERC-404 tokens
contract TokenVesting is Ownable, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct UserInfo {
    // Records all token addresses the user has locked
    EnumerableSet.AddressSet lockedTokens;
    // Map ERC20 and ERC404 token addresses for that token
    mapping(address => uint256[]) locksForToken;
  }

  struct TokenLock {
    address tokenAddress;
    uint256 sharesDeposited;
    uint256 sharesWithdrawn;
    uint256 startEmission;
    uint256 endEmission;
    uint256 lockId;
    address owner;
    address condition;
  }

  struct LockParams {
    address payable owner;
    uint256 amount;
    uint256 startEmission;
    uint256 endEmission;
    address condition;
  }

  struct FeeStruct {
    uint256 tokenFee;
    uint256 freeLockingFee;
    address payable feeAddress;
    address freeLockingToken;
  }

  EnumerableSet.AddressSet private TOKENS;
  mapping(uint256 => TokenLock) public LOCKS;
  uint256 public NONCE = 0;
  uint256 public MINIMUM_DEPOSIT = 100;

  mapping(address => uint256[]) private TOKEN_LOCKS;
  mapping(address => UserInfo) private USERS;

  mapping (address => uint256) public SHARES;

  EnumerableSet.AddressSet private ZERO_FEE_WHITELIST;
  EnumerableSet.AddressSet private TOKEN_WHITELISTERS;

  FeeStruct public FEES;

  IAdmin ALPHABET_ADMINS;
  IMigrator public MIGRATOR;
  ITokenBlacklist public BLACKLIST; // Prevent AMM tokens with a blacklisting contract


  event onLock(uint256 lockId, address token, address owner, uint256 amountInTokens, uint256 startEmission, uint256 endEmission);
  event onWithdraw(address lpToken, uint256 amountInTokens);
  event onRelock(uint256 lockId, uint256 unlockDate);
  event onTransferLock(uint256 lockIdFrom, uint256 lockIdto, address oldOwner, address newOwner);
  event onSplitLock(uint256 fromLockId, uint256 toLockId, uint256 amountInTokens);
  event onMigrate(uint256 lockId, uint256 amountInTokens);

  constructor(
    IAdmin _admins,
    uint256 _tokenFee,
    address payable _feeAddress,
    address _freeLockingToken
  ) Ownable(msg.sender) {
    ALPHABET_ADMINS = _admins;
    FEES.tokenFee = _tokenFee;
    FEES.feeAddress = _feeAddress;
    FEES.freeLockingToken = _freeLockingToken;
  }


  function setMigrator(IMigrator _migrator) external onlyOwner {
    MIGRATOR = _migrator;
  }

  function setBlacklist(ITokenBlacklist _blacklist) external onlyOwner {
    BLACKLIST = _blacklist;
  }

  function setFees(uint256 _tokenFee, uint256 _freeLockingFee, address payable _feeAddress, address _freeLockingToken) external onlyOwner {
    FEES.tokenFee = _tokenFee;
    FEES.freeLockingFee = _freeLockingFee;
    FEES.feeAddress = _feeAddress;
    FEES.freeLockingToken = _freeLockingToken;
  }

  function adminSetWhitelister(address _whitelister, bool _add) external onlyOwner {
    if(_add) {
      TOKEN_WHITELISTERS.add(_whitelister);
    } else {
      TOKEN_WHITELISTERS.remove(_whitelister);
    }
  }

  // TODO: Remove this
  function payForFreeTokenLocks (address _token) external payable {
      require(!ZERO_FEE_WHITELIST.contains(_token), 'PAID');
      // charge Fee
      if (FEES.freeLockingToken == address(0)) {
          require(msg.value == FEES.freeLockingFee, 'FEE NOT MET');
          FEES.feeAddress.transfer(FEES.freeLockingFee);
      } else {
        // TODO: Add TransferHelper
          TransferHelper.safeTransferFrom(address(FEES.freeLockingToken), address(msg.sender), FEES.feeAddress, FEES.freeLockingFee);
      }
      ZERO_FEE_WHITELIST.add(_token);
  }

  // TODO: Remove this
  function editZeroFeeWhitelist (address _token, bool _add) external {
    require(ALPHABET_ADMINS.userIsAdmin(msg.sender) || TOKEN_WHITELISTERS.contains(msg.sender), 'ADMIN');
    if (_add) {
      ZERO_FEE_WHITELIST.add(_token);
    } else {
      ZERO_FEE_WHITELIST.remove(_token);
    }
  }

  // Creates one or multiple locks for a token 
  function lock(address _token, LockParams[] calldata _lockParams) external nonReentrant {
    // TODO: Implement lock 
  }

  // Withdraw specific amount from a lock
  function withdraw(uint256 _lockId, uint256 _amount) external nonReentrant {
    // TODO: Implement withdraw 
  }

  function relock(uint256 _lockId, uint256 _unlockDate) external nonReentrant {
    // TODO: Implement relock 
  }

  function incrementLock(uint256 _lockId, uint256 _amount) external nonReentrant {
    // TODO: Implement incrementLock 
  }

  function transferLockOwnership (uint256 _lockId, address payable _newOwner) external nonReentrant {
    // TODO: Implement transferLockOwnership
  }

  // Split a lock into two different locks (useful when lock is about to expire and you want to withdraw a
  // portion of the tokens and keep the rest locked)
  function splitLock(uint256 _lockId, uint256 _amount) external nonReentrant {
    // TODO: Implement splitLock
  }

  function migrate(uint256 _lockId, uint256 _option) external nonReentrant {
    // Migrates locker version
  }

  function revokeCondition (uint256 _lockId) external nonReentrant {}

  // TODO: Do we need this?
  function testCondition(address _condition) external view returns (bool) {}

  // returns withdrawable share amount from the lock, taking into consideration start and end emission
  function getWithdrawableShares (uint256 _lockID) public view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint8 lockType = userLock.startEmission == 0 ? 1 : 2;
    uint256 amount = lockType == 1 ? userLock.sharesDeposited - userLock.sharesWithdrawn : userLock.sharesDeposited;
    uint256 withdrawable;
    withdrawable = VestingMathLibrary.getWithdrawableAmount (
      userLock.startEmission, 
      userLock.endEmission, 
      amount, 
      block.timestamp, 
      userLock.condition
    );
    if (lockType == 2) {
      withdrawable -= userLock.sharesWithdrawn;
    }
    return withdrawable;
  }
  
  // convenience function for UI, converts shares to the current amount in tokens
  function getWithdrawableTokens (uint256 _lockID) external view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint256 withdrawableShares = getWithdrawableShares(userLock.lockId);
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountTokens = FullMath.mulDiv(withdrawableShares, balance, SHARES[userLock.tokenAddress] == 0 ? 1 : SHARES[userLock.tokenAddress]);
    return amountTokens;
  }

  // For UI use
  function convertSharesToTokens (address _token, uint256 _shares) external view returns (uint256) {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    return FullMath.mulDiv(_shares, balance, SHARES[_token]);
  }

  function convertTokensToShares (address _token, uint256 _tokens) external view returns (uint256) {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    return FullMath.mulDiv(SHARES[_token], _tokens, balance);
  }
  
  // For use in UI, returns more useful lock Data than just querying LOCKS,
  // such as the real-time token amount representation of a locks shares
  function getLock (uint256 _lockID) external view returns (uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, address, address) {
      TokenLock memory tokenLock = LOCKS[_lockID];

      uint256 balance = IERC20(tokenLock.tokenAddress).balanceOf(address(this));
      uint256 totalSharesOr1 = SHARES[tokenLock.tokenAddress] == 0 ? 1 : SHARES[tokenLock.tokenAddress];
      // tokens deposited and tokens withdrawn is provided for convenience in UI, with rebasing these amounts will change
      uint256 tokensDeposited = FullMath.mulDiv(tokenLock.sharesDeposited, balance, totalSharesOr1);
      uint256 tokensWithdrawn = FullMath.mulDiv(tokenLock.sharesWithdrawn, balance, totalSharesOr1);
      return (tokenLock.lockId, tokenLock.tokenAddress, tokensDeposited, tokensWithdrawn, tokenLock.sharesDeposited, tokenLock.sharesWithdrawn, tokenLock.startEmission, tokenLock.endEmission, 
      tokenLock.owner, tokenLock.condition);
  }
  
  function getNumLockedTokens () external view returns (uint256) {
    return TOKENS.length();
  }
  
  function getTokenAtIndex (uint256 _index) external view returns (address) {
    return TOKENS.at(_index);
  }
  
  function getTokenLocksLength (address _token) external view returns (uint256) {
    return TOKEN_LOCKS[_token].length;
  }
  
  function getTokenLockIDAtIndex (address _token, uint256 _index) external view returns (uint256) {
    return TOKEN_LOCKS[_token][_index];
  }
  
  // User functions
  function getUserLockedTokensLength (address _user) external view returns (uint256) {
    return USERS[_user].lockedTokens.length();
  }
  
  function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
    return USERS[_user].lockedTokens.at(_index);
  }
  
  function getUserLocksForTokenLength (address _user, address _token) external view returns (uint256) {
    return USERS[_user].locksForToken[_token].length;
  }
  
  function getUserLockIDForTokenAtIndex (address _user, address _token, uint256 _index) external view returns (uint256) {
    return USERS[_user].locksForToken[_token][_index];
  }
  
  // No fee tokens
  function getZeroFeeTokensLength () external view returns (uint256) {
    return ZERO_FEE_WHITELIST.length();
  }
  
  function getZeroFeeTokenAtIndex (uint256 _index) external view returns (address) {
    return ZERO_FEE_WHITELIST.at(_index);
  }
  
  function tokenOnZeroFeeWhitelist (address _token) external view returns (bool) {
    return ZERO_FEE_WHITELIST.contains(_token);
  }
  
  // Whitelist
  function getTokenWhitelisterLength () external view returns (uint256) {
    return TOKEN_WHITELISTERS.length();
  }
  
  function getTokenWhitelisterAtIndex (uint256 _index) external view returns (address) {
    return TOKEN_WHITELISTERS.at(_index);
  }
  
  function getTokenWhitelisterStatus (address _user) external view returns (bool) {
    return TOKEN_WHITELISTERS.contains(_user);
  }

}