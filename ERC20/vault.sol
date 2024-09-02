// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import  {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Vault is ERC20, Ownable, ReentrancyGuard {
    uint256 suplyToken;
    uint8 immutable rewardToken = 10;

    constructor(uint256 _suplyTokken) ERC20("Volt", "VLT") Ownable(msg.sender) {
        _mint(msg.sender, _suplyTokken);
        suplyToken = _suplyTokken;
    }

    event stackToken(address indexed Wallet, uint256 tokenVault);

    struct user {
        uint256 token;
        uint256 stack;
        uint256 stackingTime;
    }

    mapping(address => user) Users;

    function buytoken(uint32 _amount) public payable {
        require(_amount <= suplyToken, "quantiter trop importante");
        uint256 currentSupply = suplyToken;
        Users[msg.sender].token += _amount;
        suplyToken = currentSupply - _amount;
    }

    function vaultStacking(uint256 _stackingAmount) public nonReentrant {
        user storage currentUser = Users[msg.sender];
        require(currentUser.token > 0, "vous n'avez rien a stocker");
        currentUser.token -= _stackingAmount;
        currentUser.stack += _stackingAmount;
        currentUser.stackingTime = block.timestamp;
        emit stackToken(msg.sender, _stackingAmount);
    }

    function rewardStacking() public nonReentrant {
        user storage currentUser = Users[msg.sender];
        require(currentUser.stackingTime + 1 weeks > block.timestamp);
        uint256 rewardtime = block.timestamp - currentUser.stackingTime;
        uint256 rewardPeriod = rewardtime / 1 weeks;
        uint256 rewards = rewardPeriod * rewardToken;
        currentUser.stack += rewards;
        currentUser.stackingTime = block.timestamp;
       
    }

    function getStacking() public view returns (uint256) {
        return Users[msg.sender].stack;
    }
}
