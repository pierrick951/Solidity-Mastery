// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract yieldFarm is Ownable, ReentrancyGuard, ERC20 {
    uint256 TokenSuplly;
    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 public constant TOKEN_PRICE = 1000 gwei;

    constructor(uint256 _tokenSuply) ERC20("Token", "TKT") Ownable(msg.sender) {
        _mint(address(this), _tokenSuply);
        TokenSuplly = _tokenSuply;
    }

    uint256 public lockTime = 1 weeks;

    modifier canClaimReward() {
        require(block.timestamp >= User[msg.sender].time + lockTime);
        _;
    }
    event Deposit(address indexed user, uint256 amount);
    event stopstacking(uint256 amount);

    struct user {
        uint256 tokenStack;
        uint256 time;
        bool hasStacking;
    }

    mapping(address => user) User;

    function deposite() public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(msg.value > 0, "Deposit must be greater than zero");

        uint256 userToken = convertToken(msg.value);
       
        CurrentUser.time = block.timestamp;
        CurrentUser.hasStacking = true;
        CurrentUser.tokenStack += userToken;

        _transfer(address(this), msg.sender, userToken);
        emit Deposit(msg.sender, msg.value);
    }
 //probleme de convertion les  montant produitun trop volume de token 
    function convertToken(uint256 _amount) internal pure returns (uint256) {
    return (_amount * PRECISION_FACTOR) / TOKEN_PRICE;
}

    function getReward() public canClaimReward {
        user storage CurrentUser = User[msg.sender];
        require(CurrentUser.hasStacking, "You dont have a stacking already");
        uint256 reward = calculReward(CurrentUser.tokenStack, CurrentUser.time);
        CurrentUser.time = block.timestamp;
        CurrentUser.tokenStack += reward;
    }

    function stopStack() public nonReentrant {
        user storage CurrentUser = User[msg.sender];

        require(CurrentUser.hasStacking, "You dont have a stacking already");

        uint256 reward = calculReward(CurrentUser.tokenStack, CurrentUser.time);
        uint256 totalRefund = reward + CurrentUser.tokenStack;
        require(
            address(this).balance >= totalRefund,
            "Contract does not have enough funds"
        );
        CurrentUser.hasStacking = false;
        CurrentUser.time = 0;
        _transfer(address(this), msg.sender, totalRefund);
        emit stopstacking(totalRefund);
    }

    function calculReward(uint256 _amount, uint256 _time)
        internal
        view
        returns (uint256)
    {
        uint256 time = block.timestamp - _time;
        uint256 rewardTime = time / 2 hours;
        return (_amount * rewardTime) * 100;
    }

    function getTokenUser() public view returns (uint256) {
        return User[msg.sender].tokenStack;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }
}
