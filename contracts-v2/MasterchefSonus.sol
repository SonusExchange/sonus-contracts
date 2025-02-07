// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

// MasterchefSonus --> visit https://sonus.exchange/ for full experience
// Made by Kell

// ──────▄▌▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▌
// ───▄▄██▌█ BEEP BEEP
// ▄▄▄▌▐██▌█ BEST DEX DELIVERY
// ███████▌█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▌
// ▀(⊙)▀▀▀▀▀▀▀(⊙)(⊙)▀▀▀▀▀▀▀▀▀▀(⊙)▀

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IVe.sol";
import "./interface/IVoter.sol";
import "./interface/IERC721.sol";
import "./interface/IGauge.sol";
import "./interface/IFactory.sol";
import "./interface/IPair.sol";
import "./interface/IBribeFactory.sol";
import "./interface/IMinter.sol";
import "./interface/IBribe.sol";
import "./interface/IMasterChefV3.sol";
import "./interface/IPairFeesV3.sol";
import "./interface/IStakingRewards.sol";
import "./interface/IStakingRewardsFactory.sol";
import "./interface/IERC20.sol";
import "./Reentrancy.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IBaseToken {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

contract MasterchefSonus is Ownable, Reentrancy, IVoter {
    using SafeMath for uint256;
    // immutables
    uint public stakingRewardsGenesis;
    uint public currentEpochPeriod;
    uint public totalAllocPoint;
    address public rewardsToken;
    uint public globalSonusPerSecond;

    address public masterchefV3;
    address public pairFeesV3;

    // Info of each pool.
    struct PoolInfo {
        address stakingFarm; // Address of Staking Farm contract.
        uint256 allocPoint; // Percent of rewards to farm
    }

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
    }

    mapping(address => bool) public isFarm;
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingFarmAddress; // rewards info by staking token
    mapping(address => uint) public poolPidByStakingFarmAddress;
    PoolInfo[] public poolInfo; // Info of each pool.

    /* VOTING */
    
    uint public totalVotingWeight; /// @dev Total voting weight of all users
    uint public totalVotingWeightV2; /// @dev Total voting weight V2 farms
    uint public totalVotingWeightV3; /// @dev Total voting weight V3 farms
    uint internal constant DURATION = 7 days; /// @dev Rewards are released over 7 days
    address public immutable override ve; /// @dev The ve token that governs these contracts
    address public immutable bribeFactory;
    address public rewardsMinterContract;
    address public stakingRewardsFactory;

    uint public maxVotingPool = 30; /// @dev Maximum number of pools a user can vote for
    
    mapping(address => bool) public isWhitelisted;
    address[] public whitelistings;

    mapping(uint => bool) public nftCantVote; /// @dev nftCantVote

    mapping(address => address) public gauges; /// @dev pool => gauge
    mapping(address => address) public poolForGauge; /// @dev gauge => pool
    mapping(address => address) public bribes; /// @dev gauge => bribe
    mapping(address => bool) public isGauge;
    mapping(address => bool) public unvotable; // disable voting for certain pools
    mapping(address => bool) public isAlive; // killed implies no emission allocation

    mapping(address => bool) public isV3Gauge; // v3 gauges

    address[] public pools; /// @dev All pools viable for incentives

    mapping(uint => address[]) public poolVote; /// @dev nft => pools
    mapping(uint => mapping(address => int256)) public votes; /// @dev nft => pool => votes
    mapping(address => int256) public weights; /// @dev pool => weight
    uint public index;
    mapping(address => uint) public supplyIndex;
    mapping(address => uint) public claimable;
    mapping(address => uint) public gaugeActivePeriod;

    /// @dev nft => total voting weight of user
    mapping(uint => uint) public usedWeights;
    mapping(uint => uint) public lastVoted; // nft => timestamp of last vote, to ensure one vote per epoch
    bool public pokable; // toggle poking

    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(address indexed voter, uint tokenId, int256 weight);
    event Abstained(uint tokenId, int256 weight);
    event Whitelisted(address indexed whitelister, address indexed token);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);

    /* END VOTING */

    modifier onlyOwnerOrMinter() {
        require(msg.sender == owner() || msg.sender == rewardsMinterContract,"!owner");
        _;
    }

    modifier onlyNewEpoch(uint _tokenId) {
        // ensure new epoch since last vote
        require((block.timestamp / DURATION) * DURATION > lastVoted[_tokenId],"TOKEN_ALREADY_VOTED_THIS_EPOCH");
        _;
    }

    constructor(address _rewardsToken, uint _stakingRewardsGenesis, address _ve, address _bribeFactory, address _stakingRewardsFactory) Ownable(msg.sender) {
        require(_stakingRewardsGenesis >= block.timestamp,"MasterChef: genesis too soon");
        ve = _ve;
        bribeFactory = _bribeFactory;
        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
        currentEpochPeriod = _stakingRewardsGenesis;
        rewardsMinterContract = msg.sender;
        stakingRewardsFactory = _stakingRewardsFactory;
    }

    function initialize(address[] memory _tokens, address _minter) external {
        require(msg.sender == rewardsMinterContract, "!rewardsMinterContract");
        for (uint i = 0; i < _tokens.length; i++) {
            _whitelist(_tokens[i]);
        }
        rewardsMinterContract = _minter;
    }

    function governor() external view returns (address) {
        return owner();
    }

    ///// permissioned functions
    function _deploy(address _pool, uint256 _farmStartTime, bool _isV3) internal { 
        require(gauges[_pool] == address(0x0), "exists");
        address[] memory allowedRewards = new address[](3);
        address tokenA;
        address tokenB;

        if (_isV3) {
            tokenA = IPancakeV3Pool(_pool).token0();
            tokenB = IPancakeV3Pool(_pool).token1();
        } else {
            (tokenA, tokenB) = IPair(_pool).tokens();
        }

        allowedRewards[0] = tokenA;
        allowedRewards[1] = tokenB;
        if (rewardsToken != tokenA && rewardsToken != tokenB) {
            allowedRewards[2] = rewardsToken;
        }

        // deploy bribe
        address _bribe = IBribeFactory(bribeFactory).createBribe(allowedRewards);
        address _gauge;
        if (_isV3) {
            _gauge = _pool;  // for v3 we consider farmAddress = poolAddress
            IMasterChefV3(masterchefV3).add(0, IPancakeV3Pool(_pool), true); // create farm is masterchef v3 (gauge)
        } else {
            _gauge = IStakingRewardsFactory(stakingRewardsFactory).createStakingRewards(
                address(this),
                owner(),
                _pool,
                0,
                _farmStartTime,
                _bribe
            );
        }

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_gauge];
        require(info.stakingRewards == address(0), "MasterChef: already deployed");
        require(_farmStartTime > stakingRewardsGenesis, "Masterchef: cant start farm before global time");

        info.stakingRewards = _gauge;
        isFarm[_gauge] = true;
        poolInfo.push(
            PoolInfo({
                stakingFarm: _gauge,
                allocPoint: 0
            })
        );
        poolPidByStakingFarmAddress[_gauge] = poolInfo.length - 1;

        bribes[_gauge] = _bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        isV3Gauge[_gauge] = _isV3 ? true : false;
        uint activePeriod = IMinter(rewardsMinterContract).activePeriod(); // get the active period (last timestamp that was updated)
        gaugeActivePeriod[_gauge] = activePeriod;
        _updateVotesFor(_gauge);
        pools.push(_pool);
        emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
    }

    function createFarmV2(address _pool, uint256 _farmStartTime) public onlyOwner {
        _deploy(_pool, _farmStartTime, false);
    }

    function createFarmV3(address _v3Pool, uint256 _farmStartTime) public onlyOwner {
        _deploy(_v3Pool, _farmStartTime, true);
    }

    function mintRewards(address _receiver, uint256 _amount) public {
        require(isFarm[msg.sender] == true, "MasterChef: only farms can mint rewards");
        require(isV3Gauge[msg.sender] == false, "MasterChef: v3 farms cannot mint rewards here");
        require(block.timestamp >= stakingRewardsGenesis, "Masterchef: rewards too soon");

        require(
            IBaseToken(rewardsToken).mint(_receiver, _amount),
            "MasterChef: mint rewardsToken failed"
        );
    }

    function pullExtraTokens(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, amount);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    function massUpdatePools() public onlyOwner {
        _massUpdatePools();
    }

    function updatePool(uint256 _pid) public onlyOwner {
        _updatePool(_pid);
    }

    function updatePoolsInRange(uint256 start, uint256 end) public onlyOwner {
        for (uint256 pid = start; pid < end; ++pid) {
            _updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (!isV3Gauge[pool.stakingFarm]) {
            StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[pool.stakingFarm];
            uint normalRewardRate = totalAllocPoint == 0
                ? globalSonusPerSecond
                : globalSonusPerSecond.mul(pool.allocPoint).div(
                    totalAllocPoint
                );

            uint256 actualRate = IStakingRewards(info.stakingRewards).rewardRate();
            if (actualRate != normalRewardRate) {
                IStakingRewards(info.stakingRewards).setRewardRate(normalRewardRate);
            }
        }
    }

    function _set(uint256 _pid, uint256 _allocPoint) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (totalAllocPoint != 0) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
            pool.allocPoint = _allocPoint;
        } else {
            totalAllocPoint = _allocPoint;
            pool.allocPoint = _allocPoint;
        }
    }

    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        _set(_pid, _allocPoint);
    }

    function setBulk(uint256[] memory _pids, uint256[] memory _allocs) public onlyOwner {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _set(_pids[pid], _allocs[pid]);
        }
    }

    /// @dev Add rewards to this contract. Usually it is SonusMinter.
    function notifyRewardAmount(uint amount) external override onlyOwnerOrMinter {
        require(amount != 0, "zero amount");
        uint _totalVotingWeight = totalVotingWeight;
        require(_totalVotingWeight != 0, "!weights"); // without votes rewards can not be added
        
        // 1e18 adjustment is removed during claim
        uint _ratio = (amount * 1e18) / _totalVotingWeight;
        if (_ratio > 0) {
            index += _ratio;
        }

        // Calculate weight percentages for v2 and v3 gauges
        uint v2WeightPercentage = (totalVotingWeightV2 * 1e18) / _totalVotingWeight;
        uint v3WeightPercentage = (totalVotingWeightV3 * 1e18) / _totalVotingWeight;
        globalSonusPerSecond = (amount * v2WeightPercentage) / (DURATION * 1e18);
        uint globalCakePerSecond = (amount * v3WeightPercentage) / (DURATION * 1e18);
        IMasterChefV3(masterchefV3).setGlobalCakePerSecond(globalCakePerSecond * 1e12); // it needs to be in 1e30 format

        emit NotifyReward(msg.sender, rewardsToken, amount);
    }

    /*********************** FARMS CONTROLS ***********************/

    function setGlobalSonusPerSecond(uint256 _globalSonusPerSecond) public onlyOwner {
        globalSonusPerSecond = _globalSonusPerSecond;
    }

    /* VOTING */
    /// @dev Remove all votes for given tokenId.
    function reset(uint _tokenId) external onlyNewEpoch(_tokenId) {
        require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
        lastVoted[_tokenId] = block.timestamp;
        _reset(_tokenId);
        IVe(ve).abstain(_tokenId);
    }

    function resetOverride(uint[] memory _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            resetOverride(_ids[i]);
        }
    }

    function resetOverride(uint _tokenId) public onlyOwner{
        _reset(_tokenId);
        IVe(ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        int256 _totalVotingWeight = 0;
        int256 _totalVotingWeightV2 = 0;
        int256 _totalVotingWeightV3 = 0;

        for (uint i = 0; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            int256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                _updateVotesFor(gauges[_pool]);
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    IBribe(bribes[gauges[_pool]])._withdraw(
                        uint256(_votes),
                        _tokenId
                    );
                    _totalVotingWeight += _votes;
                    if (isV3Gauge[gauges[_pool]]) {
                        _totalVotingWeightV3 += _votes;
                    } else {
                        _totalVotingWeightV2 += _votes;
                    }
                } else {
                    _totalVotingWeight -= _votes;
                    if (isV3Gauge[gauges[_pool]]) {
                        _totalVotingWeightV3 -= _votes;
                    } else {
                        _totalVotingWeightV2 -= _votes;
                    }
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalVotingWeight -= uint256(_totalVotingWeight);
        totalVotingWeightV2 -= uint256(_totalVotingWeightV2);
        totalVotingWeightV3 -= uint256(_totalVotingWeightV3);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function poke(uint _tokenId) external {
        if (pokable) {
            address[] memory _poolVote = poolVote[_tokenId];
            uint _poolCnt = _poolVote.length;
            int256[] memory _weights = new int256[](_poolCnt);

            for (uint i = 0; i < _poolCnt; i++) {
                _weights[i] = votes[_tokenId][_poolVote[i]];
            }

            _vote(_tokenId, _poolVote, _weights);
        }
    }

    function _vote(
        uint _tokenId,
        address[] memory _poolVote,
        int256[] memory _weights
    ) internal {
        require(nftCantVote[_tokenId] == false, "NFT cant vote");
        // todo: prevent some nfts from voting
        for (uint i = 0; i < _poolVote.length; i++) {
            require(!unvotable[_poolVote[i]], "This pool is unvotable!");
            require(
                isAlive[gauges[_poolVote[i]]],
                "Cant vote for Killed Gauges!"
            );
        }
        require(_poolVote.length <= maxVotingPool, "too many pools");

        _reset(_tokenId);
        uint _poolCnt = _poolVote.length;
        int256 _weight = int256(IVe(ve).balanceOfNFT(_tokenId));
        int256 _totalVoteWeight = 0;
        int256 _totalVotingWeight = 0;
        int256 _totalVotingWeightV2 = 0;
        int256 _totalVotingWeightV3 = 0;
        int256 _usedWeight = 0;

        for (uint i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
        }

        for (uint i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge]) {
                int256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0, "duplicate pool");
                require(_poolWeight != 0, "zero power");
                _updateVotesFor(_gauge);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                if (_poolWeight > 0) {
                    IBribe(bribes[_gauge])._deposit(
                        uint(_poolWeight),
                        _tokenId
                    );
                } else {
                    _poolWeight = -_poolWeight;
                }
                _usedWeight += _poolWeight;
                _totalVotingWeight += _poolWeight;
                if (isV3Gauge[_gauge]) {
                    _totalVotingWeightV3 += _poolWeight;
                } else {
                    _totalVotingWeightV2 += _poolWeight;
                }
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) IVe(ve).voting(_tokenId);
        totalVotingWeight += uint(_totalVotingWeight);
        totalVotingWeightV2 += uint(_totalVotingWeightV2);
        totalVotingWeightV3 += uint(_totalVotingWeightV3);
        usedWeights[_tokenId] = uint(_usedWeight);
    }

    /// @dev Vote for given pools using a vote power of given tokenId. Reset previous votes.
    function vote(
        uint tokenId,
        address[] calldata _poolVote,
        int256[] calldata _weights
    ) external onlyNewEpoch(tokenId) {
        require(IVe(ve).isApprovedOrOwner(msg.sender, tokenId), "!owner");
        require(_poolVote.length == _weights.length, "!arrays");
        lastVoted[tokenId] = block.timestamp;
        _vote(tokenId, _poolVote, _weights);
    }

    /// @dev Update given gauges.
    function updateVotesFor(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            _updateVotesFor(_gauges[i]);
        }
    }

    /// @dev Update gauges by indexes in a range.
    function updateVotesForRange(uint start, uint end) public {
        for (uint i = start; i < end; i++) {
            _updateVotesFor(gauges[pools[i]]);
        }
    }

    /// @dev Update all gauges.
    function updateVotesAll() external {
        updateVotesForRange(0, pools.length);
    }

    /// @dev Update reward info for given gauge.
    function updateVotesForGauge(address _gauge) external {
        _updateVotesFor(_gauge);
    }

    function _updateVotesFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        int256 _supplied = weights[_pool];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            // get global index for accumulated distro
            uint _index = index;
            // update _gauge current position to global position
            supplyIndex[_gauge] = _index;
            // see if there is any difference that need to be accrued
            uint _delta = _index - _supplyIndex;
            if (_delta > 0) {
                // add accrued difference for each supplied token
                uint _share = (uint(_supplied) * _delta) / 1e18;
                claimable[_gauge] += _share;
            }
        } else {
            // new users are set to the default global state
            supplyIndex[_gauge] = index;
        }
    }

    /* VOTING INFO */

    function whitelistedTokens() external view returns (address[] memory) {
        address[] memory _r = new address[](whitelistings.length);
        for (uint i; i < whitelistings.length; i++) {
            _r[i] = whitelistings[i];
        }
        return _r;
    }

    /// @dev Length of pools
    function poolsLength() external view returns (uint) {
        return pools.length;
    }

    /* VOTING TOKENS CONTROLS */

    /// @dev Add token to whitelist. Only pools with whitelisted tokens can be added to gauge.
    function whitelist(address _token) external onlyOwner {
        _whitelist(_token);
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token], "already whitelisted");
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    function removeFromWhitelist(address[] calldata _tokens) external onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            delete isWhitelisted[_tokens[i]];
            for (uint j; j < whitelistings.length; j++) {
                if (whitelistings[j] == _tokens[i]) {
                    whitelistings[i] = whitelistings[whitelistings.length - 1];
                    whitelistings.pop();
                }
            }
            emit Whitelisted(msg.sender, _tokens[i]);
        }
    }

    function setUnvotablePools(
        address[] calldata _pools,
        bool[] calldata _b
    ) external onlyOwner{
        for (uint i = 0; i < _pools.length; i++) {
            unvotable[_pools[i]] = _b[i];
        }
    }

    ///@dev designates a partner veNFT as not being able to vote
    function setNftCantVote(
        uint256 _tokenId,
        bool _status
    ) external onlyOwner {
        nftCantVote[_tokenId] = _status;
        _reset(_tokenId);
    }

    function setMaxVotingPool(uint _maxVotingPool) external onlyOwner {
        maxVotingPool = _maxVotingPool;
    }

    /* VOTING FARMS CONTROLS */

    function killFarm(address _farm, bool _withUpdate) external onlyOwner {
        require(isFarm[_farm] == true, "MasterChef: This is not active");
        require(isAlive[_farm], "gauge already dead");
        isAlive[_farm] = false;
        isFarm[_farm] = false;
        claimable[_farm] = 0;
        if (isV3Gauge[_farm]) {
            uint poolPid = IMasterChefV3(masterchefV3).v3PoolAddressPid(_farm);
            IMasterChefV3(masterchefV3).set(poolPid, 0, true); 
            if (_withUpdate) {
                IMasterChefV3(masterchefV3).upkeep(0, 7 days, true);
            }
        } else {
            StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farm];
            uint256 poolPid = poolPidByStakingFarmAddress[_farm];
            _set(poolPid, 0);
            IStakingRewards(info.stakingRewards).setRewardRate(0);
            if (_withUpdate) _massUpdatePools();
        }
        emit GaugeKilled(_farm);
    }

    function activateFarm(address _farm, bool _withUpdate) external onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farm];
        require(info.stakingRewards != address(0),"MasterChef: needs to be a dead farm");
        require(isFarm[_farm] == false, "MasterChef: This is not active");
        require(!isAlive[_farm], "gauge already alive");
        isAlive[_farm] = true;
        isFarm[_farm] = true;
        if (_withUpdate) {
            if (isV3Gauge[_farm]) {
                IMasterChefV3(masterchefV3).upkeep(0, 7 days, true);
            } else {
                _massUpdatePools();
            }
        }
        emit GaugeRevived(_farm);
    }

    function setPokable(bool _b) external onlyOwner {
        pokable = _b;
    }

    function setGaugeActivePeriod(address _gauge, uint _activePeriod) external onlyOwner {
        gaugeActivePeriod[_gauge] = _activePeriod;
    }

    function setStakingRewardsGenesis(uint _stakingRewardsGenesis) external onlyOwner {
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    function setCurrentEpochPeriod(uint _currentEpochPeriod) external onlyOwner {
        currentEpochPeriod = _currentEpochPeriod;
    }

    function setMasterchefV3(address _masterchefV3) external onlyOwner {
        masterchefV3 = _masterchefV3;
    }

    function setPairFeesV3(address _pairFeesV3) external onlyOwner {
        pairFeesV3 = _pairFeesV3;
    }

    function setRewardsMinterContract(address _rewardsMinterContract) external onlyOwner {
        rewardsMinterContract = _rewardsMinterContract;
    }

    function bulkSetFarmStartTime(address[] calldata _farms, uint256 _farmStartTime) external onlyOwner {
        for (uint i = 0; i < _farms.length; i++) {
            IStakingRewards(_farms[i]).setFarmStartTime(_farmStartTime);
        }
    }

    /* VOTING DISTRIBUTE REWARDS CONTROLS */
    /// @dev Move fees from deposited pools to bribes for given gauges.
    function distributeFees(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            // check if gauge is v3 or v2
            if (isV3Gauge[_gauges[i]]) {
                IPairFeesV3(pairFeesV3).collectV3PoolFees(IPancakeV3Pool(poolForGauge[_gauges[i]]));
            } else {
                IGauge(_gauges[i]).claimFees();
            }
        }
    }

    // needs to also check if isV3Gauge and if period has ended and set new period for the gauge
    function _distribute(address _gauge) internal lock {
        IMinter(rewardsMinterContract).updatePeriod();
        _updateVotesFor(_gauge);
        uint _claimable = claimable[_gauge];
        uint activePeriod = IMinter(rewardsMinterContract).activePeriod(); // get the active period (last timestamp that was updated)
        uint currentTimestamp = block.timestamp;
        if (currentTimestamp > (gaugeActivePeriod[_gauge] + DURATION) / DURATION * DURATION && currentTimestamp > activePeriod && _claimable / DURATION > 0 && currentTimestamp >= stakingRewardsGenesis) {
            gaugeActivePeriod[_gauge] = activePeriod; // set the active period to the current period in the minter
            claimable[_gauge] = 0;
            if (isV3Gauge[_gauge]) {
                IPairFeesV3(pairFeesV3).collectV3PoolFees(IPancakeV3Pool(poolForGauge[_gauge]));
                uint poolPid = IMasterChefV3(masterchefV3).v3PoolAddressPid(_gauge);
                IMasterChefV3(masterchefV3).set(poolPid, _claimable, false); // the allocPoint is the _claimable amount
            } else {
                IGauge(_gauge).claimFees();
                uint poolPid = poolPidByStakingFarmAddress[_gauge];
                _set(poolPid, _claimable); // the allocPoint is the _claimable amount
            }
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    /// @dev Get emission from rewardsMinterContract and notify rewards for given gauge.
    function distribute(address _gauge) external override onlyOwner{
        _distribute(_gauge);
    }

    /// @dev Distribute rewards for all pools.
    function _distributeAll() internal{
        uint length = pools.length;
        for (uint x; x < length; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    /// @dev Distribute rewards for all pools.
    function distributeAll() public onlyOwner {
        _distributeAll();
    }

    function distributeForPoolsInRange(uint start, uint finish) external onlyOwner{
        for (uint x = start; x < finish; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    function distributeForGauges(address[] memory _gauges) external onlyOwner{
        for (uint x = 0; x < _gauges.length; x++) {
            _distribute(_gauges[x]);
        }
    }

    function triggerNewEpoch() external {
        uint _period = currentEpochPeriod;
        require(block.timestamp >= _period + DURATION, "Already triggered for this epoch");

        _period = block.timestamp / DURATION * DURATION;
        currentEpochPeriod = _period;

        _distributeAll();
        _massUpdatePools();
        IMasterChefV3(masterchefV3).upkeep(0, 0, true);
    }

    /* VOTING CLAIM REWARDS CONTROLS */

    /// @dev Batch claim rewards from given gauges.
    function claimBulkV2Rewards(
        address[] memory _gauges
    ) public {
        for (uint i = 0; i < _gauges.length; i++) {
            if (!isV3Gauge[_gauges[i]]) {
                IStakingRewards(_gauges[i]).getRewardFor(msg.sender);
            }
        }
    }

    /// @dev Batch claim rewards from given bribe contracts for given tokenId.
    function claimBribes(
        address[] memory _bribes,
        address[][] memory _tokens,
        uint _tokenId
    ) public { 
        require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
        for (uint i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function claimEverything(
        address[] memory _gauges,
        // address[][] memory _gtokens,
        address[] memory _bribes,
        address[][] memory _btokens,
        uint _tokenId
    ) external {
        claimBulkV2Rewards(_gauges);
        if (_tokenId > 0) {
            claimBribes(_bribes, _btokens, _tokenId);
        }
    }
}
