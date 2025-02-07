// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVeDist {

  function checkpointToken() external;

  function checkpointTotalSupply() external;

  function setDepositor(address _depositor) external;

  function setVoteEscrow(address _votingEscrow) external;

}