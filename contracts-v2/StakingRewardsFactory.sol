// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./StakingRewards.sol";
import "./interface/IStakingRewardsFactory.sol";

contract StakingRewardsFactory is IStakingRewardsFactory {
    address public lastStakingRewards;

    event StakingRewardsCreated(address value);

    function createStakingRewards(
        address _masterChef,
        address _taxWallet,
        address _stakingToken,
        uint256 _rewardRate,
        uint256 _farmStartTime,
        address _bribe
    ) external override returns (address) {
        address _lastStakingRewards = address(new StakingRewards(_masterChef,_taxWallet,_stakingToken,_rewardRate,_farmStartTime,_bribe));
        lastStakingRewards = _lastStakingRewards;
        emit StakingRewardsCreated(_lastStakingRewards);
        return _lastStakingRewards;
    }
}
