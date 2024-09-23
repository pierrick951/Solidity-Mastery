// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract data is Ownable {

    constructor() Ownable(msg.sender) {}

    struct user {
        uint256 balance;
        uint256 deposit;
    }

    mapping(address => user) users;

    function getBalance(address _user) external view returns (uint256) {
        return users[_user].balance;
    }

    function updateDeposit(address _user, uint256 _amount) external onlyOwner {
        users[_user].deposit += _amount;
    }
}
