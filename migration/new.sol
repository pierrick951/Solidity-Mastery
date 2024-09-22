// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IOldContract {
    function balances(address account) external view returns (uint256);
    function getAllAddresses() external view returns (address[] memory);
}


contract AutoMigrateContract is Ownable,  ReentrancyGuard {
    uint256 public constant BATCH_SIZE = 150;
    IOldContract public oldContract;

    constructor(address _oldContractAddress) Ownable(msg.sender) {
        oldContract = IOldContract(_oldContractAddress);
    }

    event MigrationCompleted(address indexed user, uint256 amount);
    event BatchMigrationCompleted(uint256 userCount);

    struct userBalance {
        uint256 balance;
        bool hasMigrated;
    }

    mapping(address => userBalance) public userBalances;

    function migrateAll() public onlyOwner  nonReentrant {
        address[] memory allAddresses = oldContract.getAllAddresses();
        uint256 totalAddresses = allAddresses.length;

        for (uint256 i = 0; i < totalAddresses; i += BATCH_SIZE) {
            migrateBatch(i, BATCH_SIZE);
        }
    }

    function migrateBatch(uint256 start, uint256 batchSize) public onlyOwner  nonReentrant{
        address[] memory allAddresses = oldContract.getAllAddresses();

        uint256 end = start + batchSize;

        if (end > allAddresses.length) {
            end = allAddresses.length;
        }
        for (uint256 i = start; i < end; i++) {
            address user = allAddresses[i];
            userBalance storage currentUser = userBalances[user];

            if (!currentUser.hasMigrated) {
                uint256 oldBalance = oldContract.balances(user);

                if (oldBalance > 0) {
                    currentUser.balance = oldBalance;
                    currentUser.hasMigrated = true;
                    emit MigrationCompleted(user, oldBalance);
                }
            }
        }

        emit BatchMigrationCompleted(end - start);
    }

    function withdrawBalance() public  nonReentrant{
        userBalance storage currentUser = userBalances[msg.sender];
        uint256 amount = currentUser.balance;
        require(amount > 0, "No balance to withdraw");
        currentUser.balance = 0;
        payable(msg.sender).transfer(amount);
    }
}
