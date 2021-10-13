/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity ^0.5.8;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Pool {
    using SafeMath for uint256;
    
    string public name;

    uint256 public poolStart;
    uint256 public poolEnd;

    IERC20 public rewardToken;
    IERC20 public stakeToken;

    uint256 public rewardPerBlock;

    uint256 public TOTAL_STAKED;

    address private CONSTRUCTOR_ADDRESS;
    address private TEAM_POOL;

    mapping (address => uint256) private STAKED_AMOUNT;
    mapping (address => uint256) private CUMULATED_REWARD;
    mapping (address => uint256) private UPDATED_BLOCK;

    constructor (
        string memory _name,
        uint256 _poolStart,
        uint256 _poolEnd,
        uint256 _rewardPerBlock,
        address _rewardToken, 
        address _stakeToken,
        address _teamPool
    ) public {
        rewardToken = IERC20(_rewardToken);
        stakeToken = IERC20(_stakeToken);
        name = _name;
        poolStart = _poolStart;
        poolEnd = _poolEnd;
        rewardPerBlock = _rewardPerBlock;
        TEAM_POOL = _teamPool;
        CONSTRUCTOR_ADDRESS = msg.sender;
    }

    function claimAllReward () external{
        _updateReward(msg.sender);
        require(CUMULATED_REWARD[msg.sender] > 0, "Nothing to claim");
        uint256 amount = CUMULATED_REWARD[msg.sender];
        CUMULATED_REWARD[msg.sender] = 0;
        rewardToken.transfer(msg.sender, amount);
    }

    function stake (uint256 amount) external {
        uint256 oldBalance = stakeToken.balanceOf(address(this));
        _updateReward(msg.sender);
        stakeToken.transferFrom(msg.sender, address(this), amount);
        require(stakeToken.balanceOf(address(this)) == oldBalance.add(amount), 'Stake failed');
        STAKED_AMOUNT[msg.sender] = STAKED_AMOUNT[msg.sender].add(amount);
        TOTAL_STAKED = TOTAL_STAKED.add(amount);
    }

    function claimAndUnstake (uint256 amount) external {
        _updateReward(msg.sender);
        if(CUMULATED_REWARD[msg.sender] > 0){
            uint256 rewards = CUMULATED_REWARD[msg.sender];
            CUMULATED_REWARD[msg.sender] = 0;
            rewardToken.transfer(msg.sender, rewards);
        }
        _withdraw(msg.sender, amount);
    }

    function unstakeAll () external {
        _updateReward(msg.sender);
        _withdraw(msg.sender, STAKED_AMOUNT[msg.sender]);
    }

    function emergencyExit () external {
        _withdraw(msg.sender, STAKED_AMOUNT[msg.sender]);
    }

    function inquiryDeposit (address host) external view returns (uint256) {
        return STAKED_AMOUNT[host];
    }
    function inquiryRemainReward (address host) external view returns (uint256) {
        return CUMULATED_REWARD[host];
    }
    function inquiryExpectedReward (address host) external view returns (uint256) {
        return _calculateEarn(
            _max(0, _elapsedBlock(UPDATED_BLOCK[host])), 
            STAKED_AMOUNT[host]
        ).mul(95).div(100).add(CUMULATED_REWARD[host]);
    }

    function _withdraw (address host, uint256 amount) internal {
        STAKED_AMOUNT[host] = STAKED_AMOUNT[host].sub(amount);
        require(STAKED_AMOUNT[host] >= 0);
        TOTAL_STAKED = TOTAL_STAKED.sub(amount);
        stakeToken.transfer(host, amount);
    }

    function _updateReward (address host) internal {
        uint256 elapsed = _elapsedBlock(UPDATED_BLOCK[host]);
        if(elapsed <= 0){return;}
        UPDATED_BLOCK[host] = block.number;
        uint256 baseEarned = _calculateEarn(elapsed, STAKED_AMOUNT[host]);
        CUMULATED_REWARD[host] = baseEarned.mul(95).div(100).add(CUMULATED_REWARD[host]);
        CUMULATED_REWARD[TEAM_POOL] = baseEarned.mul(5).div(100).add(CUMULATED_REWARD[TEAM_POOL]);
    }

    function _elapsedBlock (uint256 updated) internal view returns (uint256) {
        uint256 open = _max(updated, poolStart);
        uint256 close = _min(block.number, poolEnd);
        return open >= close ? 0 : close - open;
    }

    function _calculateEarn (uint256 elapsed, uint256 staked) internal view returns (uint256) {
        if(staked == 0){return 0;}
        return elapsed.mul(staked).mul(rewardPerBlock).div(TOTAL_STAKED);
    }


    function _max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}