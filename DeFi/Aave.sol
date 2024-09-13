// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract Aave is Ownable, ReentrancyGuard {
    uint16 ratioToken;
    uint8 immutable borrow = 70;

    constructor() Ownable(msg.sender) {}

    struct user {
        uint128 amountLoan;
        uint128 collateral;
        bool hasLoan;
    }

    mapping(address => user) User;

    event _deposite( uint256 amount);
    event _loan(address indexed user, uint256 amount);
    event _refund(address indexed user, uint256 amount);
    event _liquidate(address indexed user, uint256 found);
    event _receiveFound(address indexed user, uint256 value);

    function setRatioToken(uint16 _newRatio) external onlyOwner {
        ratioToken = _newRatio;
    }

    function setdeposite(uint128 deposite) public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(msg.value >= deposite, "need more token");
        uint128 collateralUser = (deposite * ratioToken) / 100;
        CurrentUser.collateral += collateralUser;
        emit _deposite(deposite);
    }

    function setLoan(uint128 _amountLoan) public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(
            !CurrentUser.hasLoan,
            "You already have an active loan. Repay it before taking a new one."
        );
        uint128 collateralRequire = (_amountLoan * borrow) / 100;
        require(
            collateralRequire <= CurrentUser.collateral,
            "Insufissant collateral"
        );

        CurrentUser.amountLoan = _amountLoan;
        CurrentUser.hasLoan = true;

        emit _loan(msg.sender, _amountLoan);
    }

    function calculateInterest(uint256 loanAmount)
        internal
        pure
        returns (uint256)
    {
        return (loanAmount * 30) / 100;
    }

    function refund(uint256 _totalRefund) public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(CurrentUser.hasLoan, "You have nothing to refund");

        uint256 interest = calculateInterest(CurrentUser.amountLoan);
        uint256 totalRefund = CurrentUser.amountLoan + interest;

        require(msg.value >= totalRefund, "Insufficient refund amount");

        CurrentUser.hasLoan = false;
        CurrentUser.amountLoan = 0;

        payable(msg.sender).transfer(CurrentUser.collateral);
        emit _refund(msg.sender, _totalRefund);
    }
    function isLoanUndercollateralized(uint256 collateral, uint256 loanAmount) internal pure returns (bool) {
    return (collateral * 100) / loanAmount < 85; 
}


    function loanLiquidate() public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];

        require(
             isLoanUndercollateralized(CurrentUser.collateral, CurrentUser.amountLoan),
            "Undercollaterized"
        );
        CurrentUser.collateral = 0;
        CurrentUser.hasLoan = false;
        CurrentUser.amountLoan = 0;

        emit _liquidate(msg.sender, CurrentUser.collateral);
    }
}
