// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Loan is Ownable, ReentrancyGuard {
    uint256 currentBlock = block.timestamp;
    uint256 public immutable RatioMax = 150;
    uint256 public immutable Interet = 30;

    event startLoan(address indexed author, uint256 value);
    event received(address indexed sender, uint256 amount);
    event _deposite(address indexed sender, uint256 amount);
    event loanRefund(address indexed sender, uint256 amount);

    constructor() Ownable(msg.sender) {}

    struct user {
        uint256 loan;
        uint256 amount;
        uint256 timeLoan;
    }

    mapping(address => user) Users;

    function deposite() public payable nonReentrant {
        require(msg.value >= 2, "You must deposit at least 2 ether");
   
            user storage currentUser = Users[msg.sender];
            uint256 userAmount = currentUser.amount;
            userAmount += msg.value;
            emit _deposite(msg.sender, msg.value);
    }

    function setLoan(uint256 _amountLoan) public payable nonReentrant {
        user storage currentUser = Users[msg.sender];
        uint256 rangeLoan = (currentUser.amount * RatioMax) / 100;
        require(
            rangeLoan <= _amountLoan,
            "You do not have sufficient borrowing capacity."
        );
      
            currentUser.loan += _amountLoan;
            currentUser.timeLoan = block.timestamp;
            emit startLoan(msg.sender, _amountLoan);
    }

    function refundLoan() public payable nonReentrant {
        user storage currentUser = Users[msg.sender];
        uint256 userLoan = currentUser.loan;
        uint256 interetLoan = (userLoan * Interet) / 100;
        require(
            msg.value == userLoan + interetLoan,
            "Incorrect repayment amount."
        );
     
            assert(msg.value == userLoan + interetLoan);
            resetUserLoan((msg.sender));
            emit loanRefund(msg.sender, interetLoan);
    }

    function resetUserLoan(address _user) internal {
        user storage currentUser = Users[_user];
        currentUser.amount = 0;
        currentUser.loan = 0;
        currentUser.timeLoan = 0;
    }

    function getLoan() public onlyOwner {
        user storage currentUser = Users[msg.sender];
        require(currentUser.loan > 0, "No active loan to liquidate.");
        require(currentUser.timeLoan + 2 weeks > block.timestamp);
            payable(address(this)).transfer(currentUser.amount);
    }

    receive() external payable {
        emit received(msg.sender, msg.value);
    }

    fallback() external payable {
        revert("Fonction non reconnue, transaction annulee.");
    }
}
