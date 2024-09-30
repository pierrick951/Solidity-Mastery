// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Logique {
    uint public count;

    function increment() external {
        count += 1;
    }
}
