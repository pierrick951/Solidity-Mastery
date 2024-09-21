// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract OldContract {
    mapping(address => uint256)  public balances;

    function deposite() public payable {
        balances[msg.sender] += msg.value;
    }
}
