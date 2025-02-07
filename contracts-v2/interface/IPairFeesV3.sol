// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IPancakeV3Pool.sol";

interface IPairFeesV3 {

    function collectV3PoolFees(IPancakeV3Pool v3Pool) external;

    function setTaxWallet(address _taxWallet) external;

    function setTaxWalletFees(uint256 _teamFeesPercent) external;

}
