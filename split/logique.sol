// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface dataContract {
    //acces au data  via interface
}

contract Logique {
    dataContract public datastock;
    constructor(address _adressdata) {
        datastock = dataContract(_adressdata);
    }

    function getbalance() public view returns (uint256) {}

    function deposite(uint256 _deposite) public payable {}
}
