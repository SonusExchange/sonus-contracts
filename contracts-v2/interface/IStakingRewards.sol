// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStakingRewards {
    // Views
    function rewardPerToken() external view returns (uint256);

    function rewardRate() external view returns (uint256);
    
    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;
    
    function getRewardFor(address account) external;

    function setRewardRate(uint256 _rewardRate) external;

    function setFarmStartTime(uint256 _farmStartTime) external;

    function exit() external;
}