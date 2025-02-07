// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVoter {

  function gauges(address pool) external view returns (address gauge);

  function bribes(address gauge) external view returns (address bribe);

  function isAlive(address) external view returns (bool);

  function ve() external view returns (address);

  function nftCantVote(uint256 tokenId) external view returns (bool);

  function governor() external view returns (address);

  function distribute(address _gauge) external;

  function notifyRewardAmount(uint amount) external;

  function isWhitelisted(address token) external view returns (bool);

}
