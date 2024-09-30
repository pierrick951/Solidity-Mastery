// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract data {
    address public implementation;


    constructor(address _implementation){
        implementation = _implementation;
    }
    
}
