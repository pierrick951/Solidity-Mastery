// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract OldContract {
    struct User {
        uint256 balances;
    }

    mapping(address => User) Users;
    mapping(address => bool) private hasDeposited;
    address[] private allUsers;

    function deposite(uint256 _deposite) public payable {
        Users[msg.sender].balances = _deposite;
        
        if (!hasDeposited[msg.sender]) {
            allUsers.push(msg.sender);
            hasDeposited[msg.sender] = true;
        }
    }

    function balances(address account) external view returns (uint256) {
        return Users[account].balances;
    }

    function getAllAddresses() external view returns (address[] memory) {
        return allUsers;
    }
}
