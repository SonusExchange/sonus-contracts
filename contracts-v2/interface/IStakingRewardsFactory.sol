// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IStakingRewardsFactory {
    function createStakingRewards(
        address _masterChef,
        address _taxWallet,
        address _stakingToken,
        uint256 _rewardRate,
        uint256 _farmStartTime,
        address _bribe
    ) external returns (address);
}
