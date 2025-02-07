// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

// PairFeesV3 --> visit https://sonus.exchange/ for full experience
// Made by Kell

// ──────▄▌▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▌
// ───▄▄██▌█ BEEP BEEP
// ▄▄▄▌▐██▌█ BEST DEX DELIVERY
// ███████▌█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▌
// ▀(⊙)▀▀▀▀▀▀▀(⊙)(⊙)▀▀▀▀▀▀▀▀▀▀(⊙)▀

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IVoter.sol";
import "./interface/IBribe.sol";
import "./interface/IPancakeV3Pool.sol";

contract PairFeesV3 {
    using SafeERC20 for IERC20;

    address public taxWallet;
    IVoter public voter; // is the masterchefv2

    uint256 public teamFeesPercent = 1000; // 10%
    uint256 public constant PRECISION = 10000;

    modifier onlyTaxWallet() {
        require(msg.sender == taxWallet, "!taxWallet");
        _;
    }

    constructor(address _voter) {
        taxWallet = msg.sender;
        voter = IVoter(_voter);
    }

    event ClaimV3Fees(address indexed v3Pool, uint256 token0Amount, uint256 token1Amount, uint256 token0AmountForTaxWallet, uint256 token1AmountForTaxWallet);

    function collectV3PoolFees(IPancakeV3Pool v3Pool) public {
        IERC20 token0 = IERC20(v3Pool.token0());
        IERC20 token1 = IERC20(v3Pool.token1());
        address v3Farm = voter.gauges(address(v3Pool));
        bool v3FarmActive = voter.isAlive(v3Farm);

        if (v3Farm == address(0) || !v3FarmActive) {
            (uint128 _amount0, uint128 _amount1) = v3Pool.collectProtocol(taxWallet, type(uint128).max, type(uint128).max);
            emit ClaimV3Fees(address(v3Pool), 0, 0, _amount0, _amount1);
            return;
        }

        IBribe v3PoolBribeContract = IBribe(voter.bribes(v3Farm));
        v3Pool.collectProtocol(address(this), type(uint128).max, type(uint128).max);

        uint256 _teamFeesPercent = teamFeesPercent;
        uint256 token0Amount = token0.balanceOf(address(this));
        uint256 token1Amount = token1.balanceOf(address(this));
        uint256 token0AmountForTaxWallet;
        uint256 token1AmountForTaxWallet;

        if (_teamFeesPercent > 0) {
            token0AmountForTaxWallet = (token0Amount * _teamFeesPercent) / PRECISION;
            token1AmountForTaxWallet = (token1Amount * _teamFeesPercent) / PRECISION;
            token0Amount = token0Amount - token0AmountForTaxWallet;
            token1Amount = token1Amount - token1AmountForTaxWallet;

            token0.safeTransfer(taxWallet, token0AmountForTaxWallet);
            token1.safeTransfer(taxWallet, token1AmountForTaxWallet);
        }

        token0.approve(address(v3PoolBribeContract), token0Amount);
        token1.approve(address(v3PoolBribeContract), token1Amount);
        v3PoolBribeContract.notifyRewardAmount(address(token0), token0Amount);
        v3PoolBribeContract.notifyRewardAmount(address(token1), token1Amount);

        emit ClaimV3Fees(address(v3Pool), token0Amount, token1Amount, token0AmountForTaxWallet, token1AmountForTaxWallet);
    }

    function setTaxWallet(address _taxWallet) public onlyTaxWallet {
        taxWallet = _taxWallet;
    }

    function setTaxWalletFees(uint256 _teamFeesPercent) public onlyTaxWallet {
        require(_teamFeesPercent <= PRECISION, ">100%");
        teamFeesPercent = _teamFeesPercent;
    }

    function setVoter(address _voter) public onlyTaxWallet {
        voter = IVoter(_voter);
    }
}