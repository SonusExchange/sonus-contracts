// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFactory {
  function isPair(address pair) external view returns (bool);

  function getFee() external view returns(uint256);

  function getInitializable() external view returns (address, address);

  function pairCodeHash() external pure returns (bytes32);

  function getPair(address tokenA, address token) external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}
