// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ioldContract {
   function  balance(address acount) external view returns (uint256);
   function getAllAddresses() external view returns (address[] memory);
}

contract Automigration is Ownable, ReentrancyGuard {
      
      uint256 public constant BATCH_SIZE = 150;
      ioldContract public oldcontract;

      constructor(address _oldcontractAdress) Ownable(msg.sender) { 
        oldcontract = ioldContract(_oldcontractAdress);
      }

      event migrationComplete(address indexed user, uint256 amount);
      event BatchMigration(uint256 userCount);


} 