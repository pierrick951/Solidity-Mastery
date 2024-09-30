// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract Stacking is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    IERC20 public tokenContract;

    uint32 public constant LOCK_TIME = 1 weeks;
    uint8 public constant REWARD_RATE = 100;

    event Stacked(address indexed user, uint256 amountStack);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event GetReward(address indexed user, uint256 amount);

    struct user {
        uint256 stake;
        uint256 timeStaked;
        uint256 lastRewardTime;
        bool hasStake;
    }
    mapping(address => user) users;
    uint128 public totalStaked;
    uint128 public totalRewards;

    constructor(address _tokenContractAddress) Ownable(msg.sender) {
        tokenContract = IERC20(_tokenContractAddress);
    }

    modifier canClaimReward() {
        require(
            block.timestamp >= users[msg.sender].timeStaked + LOCK_TIME,
            "Lock time not elaspsed"
        );
        _;
    }

    function stackTokens(uint256 _amountStaked) public payable nonReentrant {
        require(_amountStaked > 0, "Amount must be greater than 0");
        user storage currentUser = users[msg.sender];
        require(!currentUser.hasStake, "You have already a stack");

        require(
            tokenContract.balanceOf(msg.sender) >= _amountStaked,
            "Not enough Token provided"
        );

        tokenContract.safeTransferFrom(
            msg.sender,
            address(this),
            _amountStaked
        );

        currentUser.hasStake = true;
        currentUser.timeStaked = block.timestamp;
        currentUser.lastRewardTime = block.timestamp;
        currentUser.stake = _amountStaked;
        totalStaked += uint128(_amountStaked);

        emit Stacked(msg.sender, _amountStaked);
    }

    function calculateReward(address _user) internal view returns (uint256) {
        user memory currentUser = users[_user];
        if (!currentUser.hasStake) return 0;

        uint256 timeElapsed = block.timestamp - currentUser.lastRewardTime;
        uint256 weekPassed = timeElapsed / 1 weeks;
        return (currentUser.stake * weekPassed * REWARD_RATE) / 10000;
    }

    function claimReward() public canClaimReward {
        require(totalRewards > 0, " Any Rewards avaible");
        user storage currentUser = users[msg.sender];
        require(currentUser.hasStake, "You don'thave an active stack");
        require(
            block.timestamp >= currentUser.timeStaked + LOCK_TIME,
            "Lock time not elapsed"
        );

        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards to claim");
        require(reward <= totalRewards, "Not enough rewards available");

        currentUser.lastRewardTime = block.timestamp;
        totalRewards -= uint128(reward);

        tokenContract.safeTransfer(msg.sender, reward);

        emit GetReward(msg.sender, reward);
    }

    function unStack() public nonReentrant {
        user storage currentUser = users[msg.sender];
        require(currentUser.hasStake, "You don't have an active stack");
        
        require(
            block.timestamp >= currentUser.timeStaked + LOCK_TIME,
            "Lock time not elapsed"
        );

        uint256 reward = calculateReward(msg.sender);
        uint256 totalAmount = reward + currentUser.stake;
        currentUser.hasStake = false;
        totalStaked -= uint128(currentUser.stake);

        tokenContract.safeTransfer(msg.sender, totalAmount);
        emit Unstaked(msg.sender, currentUser.stake, reward);

        delete users[msg.sender];
    }

    function getStakeInfo() public view returns (uint256, uint256, bool) {
        user memory currentUser = users[msg.sender];
        return (
            currentUser.stake,
            currentUser.timeStaked,
            currentUser.hasStake
        );
    }

    function addRewards(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        tokenContract.safeTransferFrom(msg.sender, address(this), _amount);
        totalRewards += uint128(_amount);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }
}
