// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./lib/Math.sol";
import "./lib/SafeERC20.sol";
import "./interface/IUnderlying.sol";
import "./interface/IVoter.sol";
import "./interface/IVe.sol";
import "./interface/IVeDist.sol";
import "./interface/IGauge.sol";
import "./interface/IMinter.sol";
import "./interface/IERC20.sol";

/// @title Codifies the minting rules as per ve(3,3),
///        abstracted from the token to support any token that allows minting
contract SonusMinter is IMinter {
  using SafeERC20 for IERC20;

  uint internal numEpoch;
  uint public lastUpdatedEpoch;

  /// @dev Allows minting once per week (reset every Thursday 00:00 UTC)
  uint internal constant _WEEK = 86400 * 7;
  uint internal constant _LOCK_PERIOD = 86400 * 7 * 104; // 104 weeks

  /// @dev Increase weekly emission by 3% per week at the start
  uint public emissionValue = 1030;
  /// @dev Weekly emission threshold for the end game. 4% of locked supply.
  uint internal constant _LOCKED_EMISSION = 40;
  /// @dev Team weekly emission threshold for the end game. 5% of weekly emissions.
  uint public teamRate = 50;
  uint internal constant PRECISION = 1000;

  /// @dev The core parameter for determinate the whole emission dynamic.
  ///       Will be decreased every week.
  uint internal constant _START_BASE_WEEKLY_EMISSION = 10_000_000e18;


  IUnderlying public immutable token;
  IVe public immutable ve;
  address public voterContract;
  address public veDist;
  uint public baseWeeklyEmission = _START_BASE_WEEKLY_EMISSION;
  uint public activePeriod;
  address public team;
  bool public configEnabled = true;

  address internal initializer;

  event Mint(
    address indexed sender,
    uint weekly,
    uint teamEmissions,
    uint epoch
  );

  modifier onlyTeam() {
    require(msg.sender == team, "Not team");
    _;
  }

  constructor(
    address ve_, // the ve(3,3) system that will be locked into
    address voterContract_, // voterContract with voter addresses
    address veDist_, // voterContract with voter addresses
    uint warmingUpPeriod // 2 by default
  ) {
    initializer = msg.sender;
    team = msg.sender;
    token = IUnderlying(IVe(ve_).token());
    ve = IVe(ve_);
    voterContract = voterContract_;
    veDist = veDist_;
    activePeriod = (block.timestamp + (warmingUpPeriod * _WEEK)) / _WEEK * _WEEK;
  }

  /// @dev Mint initial supply to holders and lock it to ve token.
  function initialize(
    address[] memory claimants,
    uint[] memory amounts,
    uint totalAmount
  ) external {
    require(initializer == msg.sender, "Not initializer");
    token.mint(address(this), totalAmount);
    token.approve(address(ve), type(uint).max);
    uint sum;
    for (uint i = 0; i < claimants.length; i++) {
      ve.createLockFor(amounts[i], _LOCK_PERIOD, claimants[i]); // CREATE LOCKs to distribute
      sum += amounts[i];
    }
    require(sum == totalAmount, "Wrong totalAmount");
    initializer = address(0);
    activePeriod = 1739577600;
  }

  function setTeam(address _newTeam) external onlyTeam {
    team = _newTeam;
  }

  function _veDist() internal view returns (IVeDist) {
    return IVeDist(veDist);
  }

  /// @dev Weekly emission takes the max of calculated (aka target) emission versus locked emission
  function weeklyEmission() external view returns (uint) {
    return _weeklyEmission();
  }

  function _weeklyEmission() internal view returns (uint) {
    return (baseWeeklyEmission * emissionValue) / PRECISION;
  }
  /// @dev Rebase is a function of weekly emission, locked supply and total supply
  function _rebase() internal view returns (uint) {
    uint256 _veTotal = ve.totalSupplyAt(activePeriod - 1);
    uint256 _sonusTotal = token.totalSupply();

    return (((_weeklyEmission() * (_sonusTotal - _veTotal)) / _sonusTotal) * (_sonusTotal - _veTotal)) / _sonusTotal / 2;
  }
  // new rebase tek
  function rebase() external view returns (uint) {
    return _rebase();
  }

  function updateEmissionValueTail(bool _increase) external onlyTeam {
    require(numEpoch > 105, "Not in tail");
    require(lastUpdatedEpoch < numEpoch, "Already updated");
    lastUpdatedEpoch = numEpoch;
    emissionValue = _increase ? emissionValue + 1 : emissionValue - 1;
  }

  /// @dev Update period can only be called once per cycle (1 week)
  function updatePeriod() external override returns (uint) {
    uint _period = activePeriod;
    // only trigger if new week
    if (block.timestamp >= _period + _WEEK && initializer == address(0)) {
      _period = block.timestamp / _WEEK * _WEEK;
      activePeriod = _period;
      uint _weekly = _weeklyEmission();
      uint _rebaseAmount = _rebase(); // new rebase tek
      // slightly decrease weekly emission
      baseWeeklyEmission = baseWeeklyEmission * emissionValue / PRECISION;

      uint _teamEmissions = (teamRate * _weekly) / PRECISION;
      uint _balanceOf = token.balanceOf(address(this));
      if (_balanceOf < _teamEmissions + _rebaseAmount) { // new rebase tek
        token.mint(address(this), (_teamEmissions + _rebaseAmount) - _balanceOf); // new rebase tek
      }

      unchecked {
          ++numEpoch;
      }
      if (numEpoch == 1) emissionValue = 1030; // after epoch 0 it increases 3% per week
      if (numEpoch == 15) emissionValue = 990; // after epoch 13 it decreases 1% per week
      if (numEpoch == 104) emissionValue = 999; // after epoch 103 it decreases 0.1% per week

      require(token.transfer(team, _teamEmissions));

      IERC20(address(token)).safeTransfer(address(_veDist()), _rebaseAmount); // new rebase tek
      // checkpoint token balance that was just minted in veDist
      _veDist().checkpointToken();
      // checkpoint supply
      _veDist().checkpointTotalSupply();

      IVoter(voterContract).notifyRewardAmount(_weekly);

      emit Mint(msg.sender, _weekly, _teamEmissions, numEpoch);
    }
    return _period;
  }

  function setMinterContractOnVe(address _minterContract) external onlyTeam {
    IVe(ve).setMinterContract(_minterContract);
  }

  function setVoterContractOnVe(address _voterContract) external onlyTeam {
    IVe(ve).setVoterContract(_voterContract);
  }

  function setVeDistContract(address _veDistNew) external onlyTeam {
    veDist = _veDistNew;
  }

  function setDepositorOnVeDist(address _depositor) external onlyTeam {
    _veDist().setDepositor(_depositor);
  }

  function setVoteEscrowOnVeDist(address _voteEscrow) external onlyTeam {
    _veDist().setVoteEscrow(_voteEscrow);
  }

  function setActivePeriod(uint _activePeriod, bool _disableSetActivePeriod) external onlyTeam {
    require(configEnabled, "Config disabled");
    activePeriod = _activePeriod;
    if (_disableSetActivePeriod) {
      configEnabled = false;
    }
  }

}
