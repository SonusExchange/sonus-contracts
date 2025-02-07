// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./interface/IFactory.sol";
import "./SonusPair.sol";

contract SonusFactory is IFactory {
  bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(type(SonusPair).creationCode);

  uint256 public volatileFee;
  uint256 public constant MAX_FEE = 500; // 5%
  address public feeManager;
  address public pendingFeeManager;

  mapping(address => mapping(address => address)) public override getPair;
  address[] public allPairs;
  /// @dev Simplified check if its a pair, given that `stable` flag might not be available in peripherals
  mapping(address => bool) public override isPair;

  address internal _temp0;
  address internal _temp1;
  bool internal _temp;

  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint allPairsLength
  );

  constructor() {
    feeManager = msg.sender;
    volatileFee = 30; // 0.3%
  }

  function allPairsLength() external view returns (uint) {
    return allPairs.length;
  }

  function setFeeManager(address _feeManager) external {
        require(msg.sender == feeManager, "not fee manager");
        pendingFeeManager = _feeManager;
    }

  function acceptFeeManager() external {
      require(msg.sender == pendingFeeManager, "not pending fee manager");
      feeManager = pendingFeeManager;
  }

  function setFee(uint256 _fee) external {
      require(msg.sender == feeManager, "not fee manager");
      require(_fee <= MAX_FEE, "fee too high");
      require(_fee != 0, "fee must be nonzero");
          volatileFee = _fee;
  }

  function setPoolSwapFee(address pair, uint256 _fee) external {
      require(msg.sender == feeManager, "not fee manager");
      SonusPair(pair).setSwapFee(_fee);
  }

  function getFee() public view returns(uint256) { // check initial pool fees at creation
      return volatileFee;
  }

  function pairCodeHash() external pure override returns (bytes32) {
    return keccak256(type(SonusPair).creationCode);
  }

  function getInitializable() external view override returns (address, address) {
    return (_temp0, _temp1);
  }

  function createPair(address tokenA, address tokenB)
  external override returns (address pair) {
    require(tokenA != tokenB, 'SonusFactory: IDENTICAL_ADDRESSES');
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'SonusFactory: ZERO_ADDRESS');
    require(getPair[token0][token1] == address(0), 'SonusFactory: PAIR_EXISTS');
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    (_temp0, _temp1) = (token0, token1);
    pair = address(new SonusPair{salt : salt}());
    getPair[token0][token1] = pair;
    // populate mapping in the reverse direction
    getPair[token1][token0] = pair;
    allPairs.push(pair);
    isPair[pair] = true;
    emit PairCreated(token0, token1, pair, allPairs.length);
  }
}
