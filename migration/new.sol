// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


contract New { 
    
    address OldContract;

    mapping(address => uint256) public balances;

    constructor(address  _OldContractAdress) {
        OldContract = _OldContractAdress;
    }



    function migrate() public { 
        require(balances[msg.sender] == 0 );
        
        uint256 oldBalance = OldContract.balances(msg.sender);
        require(oldBalance > 0, "no balance  to migrate ");


        balances[msg.sender]  = oldBalance;



    }
}