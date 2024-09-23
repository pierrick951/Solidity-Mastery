    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract AaveVersion2 is Ownable, ReentrancyGuard {
    uint8 constant BORROW_RATIO = 30;
    uint8 constant MIN_COLLATERAL = 90;

    constructor() Ownable(msg.sender){}

    struct User {
        uint256 amountLoan;
        uint256 collateral;
        uint256 timeLoan;
        bool hasLoan;
    }

    event Deposit(address indexed user, uint256 amount);
    event Loan(address indexed user, uint256 amount);
    event Refund(address indexed user, uint256 amount);
    event Liquidate(address indexed user);

    mapping(address => User) private users;

    function deposit() public payable nonReentrant {
        User storage currentUser = users[msg.sender];
        currentUser.collateral += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function setLoan(uint256 amountLoan) public nonReentrant {
        User storage currentUser = users[msg.sender];
        uint256 requiredCollateral = (amountLoan * BORROW_RATIO) / 100;
        
        require(!currentUser.hasLoan, "Active loan exists");
        require(currentUser.collateral >= requiredCollateral, "Insufficient collateral");

        currentUser.hasLoan = true;
        currentUser.amountLoan = amountLoan;
        currentUser.timeLoan = block.timestamp;

        emit Loan(msg.sender, amountLoan);
    }

    function refund() public payable nonReentrant {
        User storage currentUser = users[msg.sender];
        require(currentUser.hasLoan, "No active loan");

        uint256 interest = calculateInterest(currentUser.amountLoan, currentUser.timeLoan);
        uint256 totalRefund = currentUser.amountLoan + interest;

        require(msg.value == totalRefund, "Insufficient refund amount");
        currentUser.amountLoan = 0;
        currentUser.hasLoan = false;

        payable(msg.sender).transfer(currentUser.collateral);
        emit Refund(msg.sender, msg.value);
    }

    function calculateInterest(uint256 amountLoan, uint256 timeLoan) internal view returns (uint256) {
        uint256 userTimeLoan = block.timestamp - timeLoan;
        uint256 timePeriod = userTimeLoan / 1 days;
        return (amountLoan * 5 / 100) * timePeriod;
    }

    function liquidate() public nonReentrant {
        User storage currentUser = users[msg.sender];
        require(underCollateralized(currentUser), "Not under-collateralized");

        currentUser.hasLoan = false;
        currentUser.amountLoan = 0;

        payable(msg.sender).transfer(currentUser.collateral);
        emit Liquidate(msg.sender);
    }

    function underCollateralized(User storage currentUser) internal view returns (bool) {
        return (currentUser.collateral * 100) / currentUser.amountLoan < MIN_COLLATERAL;
    }

    function getMyCollateral() public view returns (uint256) {
        return users[msg.sender].collateral;
    }
}
