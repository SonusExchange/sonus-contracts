// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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

import "./interface/IERC20.sol";


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



interface IMasterChef {
    function mintRewards(address _receiver, uint256 _amount) external;
}

import "./interface/IStakingRewards.sol";
import "./interface/IPair.sol";
import "./interface/IBribe.sol";
import "./interface/IMultiRewardsPool.sol";
import "./Reentrancy.sol";

contract StakingRewards is IStakingRewards, Reentrancy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    address public masterChef;
    address public taxWallet;
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public farmStartTime;
    uint256 public taxPercentage;

    /* ========== VE(3,3) CODE ========== */
    uint public fees0;
    uint public fees1;
    address public bribe;

    event ClaimFees(address indexed from, uint claimed0, uint claimed1);
    /* ========== VE(3,3) CODE END ========== */

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    modifier onlyMasterChefOrTaxWallet() {
        require(msg.sender == masterChef || msg.sender == taxWallet, "Caller is not MasterChef contract");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _masterChef,
        address _taxWallet,
        address _stakingToken,
        uint256 _rewardRate,
        uint256 _farmStartTime,
        address _bribe
    ) {
        taxWallet = _taxWallet;
        masterChef = _masterChef;
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
        farmStartTime = _farmStartTime;
        bribe = _bribe;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        if (block.timestamp < farmStartTime) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                (block.timestamp).sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external lock updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        uint256 _newAmount = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _newAmount;

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external lock updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        uint256 _newAmount = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _newAmount;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public lock updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public lock updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IMasterChef(masterChef).mintRewards(msg.sender, reward);
        }
    }

    function getRewardFor(address account) public lock updateReward(account) {
        require(msg.sender == account || msg.sender == masterChef, "Forbidden");
        uint256 reward = rewards[account];
        if (reward > 0) {
            rewards[account] = 0;
            IMasterChef(masterChef).mintRewards(account, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint256 periodFinish);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, uint256 rewardType);

    /* ========== FARMS CONTROLS ========== */

    function setRewardRate(uint256 _rewardRate) public onlyMasterChefOrTaxWallet {
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }

    function setFarmStartTime(uint256 _farmStartTime) public onlyMasterChefOrTaxWallet {
        require(block.timestamp < farmStartTime, "Farm already started");
        require(_farmStartTime >= block.timestamp, "Cannot set farmStartTime in the past");
        farmStartTime = _farmStartTime;
        lastUpdateTime = block.timestamp;
    }

    function setTaxPercentage(uint256 _taxPercentage) public onlyMasterChefOrTaxWallet {
        require(_taxPercentage <= 10000, "Invalid tax percentage");
        taxPercentage = _taxPercentage;
    }

    function setMasterChef(address _masterChef) public {
        require(taxWallet == msg.sender, "Not the owner");
        masterChef = _masterChef;
    }

    function setBribeContract(address _bribe) public {
        require(taxWallet == msg.sender, "Not the owner");
        bribe = _bribe;
    }

    /* ========== VE(3,3) CODE ========== */

    function claimFees() external lock returns (uint claimed0, uint claimed1) {
        return _claimFees();
    }

    function _claimFees() internal returns (uint claimed0, uint claimed1) {
        address _stakingToken = address(stakingToken);
        (claimed0, claimed1) = IPair(_stakingToken).claimFees();
        if (claimed0 > 0 || claimed1 > 0) {
        uint _fees0 = fees0 + claimed0;
        uint _fees1 = fees1 + claimed1;
        (address _token0, address _token1) = IPair(_stakingToken).tokens();

        uint256 taxAmount0 = (_fees0 * taxPercentage) / 10000;
        uint256 taxAmount1 = (_fees1 * taxPercentage) / 10000;

        // Send tax portion to taxWallet
        if (taxAmount0 > 0) {
            IERC20(_token0).safeTransfer(taxWallet, taxAmount0);
            _fees0 -= taxAmount0;
        }
        if (taxAmount1 > 0) {
            IERC20(_token1).safeTransfer(taxWallet, taxAmount1);
            _fees1 -= taxAmount1;
        }

        if (_fees0 > IMultiRewardsPool(bribe).left(_token0)) {
            fees0 = 0;
            IERC20(_token0).safeIncreaseAllowance(bribe, _fees0);
            IBribe(bribe).notifyRewardAmount(_token0, _fees0);
        } else {
            fees0 = _fees0;
        }
        if (_fees1 > IMultiRewardsPool(bribe).left(_token1)) {
            fees1 = 0;
            IERC20(_token1).safeIncreaseAllowance(bribe, _fees1);
            IBribe(bribe).notifyRewardAmount(_token1, _fees1);
        } else {
            fees1 = _fees1;
        }

        emit ClaimFees(msg.sender, claimed0, claimed1);
        }
    }

    // function notifyRewardAmount(address token, uint amount) external {
    //     _claimFees();
    // }
}

interface IUniswapV2ERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}