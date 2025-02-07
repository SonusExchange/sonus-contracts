// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IPancakeV3Pool.sol";

interface IMasterChefV3 {
    function latestPeriodEndTime() external view returns (uint256);

    function latestPeriodStartTime() external view returns (uint256);

    function upkeep(uint256 amount, uint256 duration, bool withUpdate) external;

    function add(uint256 _allocPoint, IPancakeV3Pool _v3Pool, bool _withUpdate) external;

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

    function setGlobalCakePerSecond(uint256 _globalCakePerSecond) external;

    function v3PoolAddressPid(address poolAddress) external view returns (uint256);

}
