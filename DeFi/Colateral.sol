// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract AdvancedLoan is Ownable, ERC20, ReentrancyGuard {
    uint32 tokenPrice;
    uint32 tokenSuply;
    uint256 immutable Loken = 100 gwei;

    uint256 borrow = 66;

    constructor(uint32 _tokenSuplly, uint32 _tokenPrice)
        ERC20("Loken", "LKN")
        Ownable(msg.sender)
    {
        _mint(msg.sender, _tokenSuplly);

        tokenPrice = _tokenPrice;
        tokenSuply = _tokenSuplly;
    }

    function burnToken(uint256 _burnToken) public onlyOwner {
        _burn(msg.sender, _burnToken);
    }

    struct user {
        uint32 tokenLoan;
        uint256 collaterale;
        uint256 amountLoan;
        bool hasloan;
    }

    mapping(address => user) Users;

    event deposite(address indexed user, uint32 _amount);
    event loan(address indexed user, uint256 _amount);
    event refund(address indexed user, uint256 _amount);
    event liquidate(address indexed user, address indexed userLiquidate);
    event receiveTransac(address indexed user, uint256 value);

    function buyToken(uint32 _amount) public payable nonReentrant {
        user storage CurentUser = Users[msg.sender];
        require(
            msg.sender.balance > _amount * tokenPrice,
            "You have a not necessary fund"
        );
        require(!CurentUser.hasloan, "You have already a loan");
        CurentUser.tokenLoan += _amount;
    }

    function setDeposite(uint32 _deposite) public payable nonReentrant {
        user storage CurentUser = Users[msg.sender];
        uint256 requiredCollateral = _deposite * Loken;
        CurentUser.collaterale += requiredCollateral;

        emit deposite(msg.sender, _deposite);
    }

    function setLoan(uint256 _amount) public payable nonReentrant {
        user storage CurrentUser = Users[msg.sender];
        require(
            !CurrentUser.hasloan,
            "You already have a loan, please refund it before applying for a new one"
        );

        uint256 requiredCollateral = (_amount * borrow) / 100;
        require(
            CurrentUser.collaterale >= requiredCollateral,
            "Insufficient collateral"
        );

        uint256 interet = (_amount * 30) / 100;
        uint256 totalAmount = interet + _amount;
        CurrentUser.amountLoan += totalAmount;
        CurrentUser.hasloan = true;
        emit loan(msg.sender, _amount);
    }

    function refundLoan(uint256 _amount) public payable nonReentrant {
        user storage CurrentUser = Users[msg.sender];
        require(CurrentUser.hasloan, "You dont have a loan");
          uint256 totalRepayment = CurrentUser.amountLoan;
        require(
            CurrentUser.amountLoan >= totalRepayment,
            "Amount is less than the total repayment"
        );
        payable(address(this)).transfer(totalRepayment);
         CurrentUser.collaterale = 0;
        CurrentUser.amountLoan = 0;
        CurrentUser.hasloan = false;
        emit refund(msg.sender, _amount);
    }

    function getLiquidate(address _address) public payable nonReentrant {
        user storage CurrentUser = Users[_address];
         uint256 requiredCollateral = (CurrentUser.amountLoan * borrow) / 100;
        require(CurrentUser.collaterale < requiredCollateral, "loan liquidate");

          uint256 liquidatedAmount = CurrentUser.collaterale;
        payable(address(this)).transfer(liquidatedAmount);
        uint256 rewards = (CurrentUser.amountLoan * 5) / 100;
        payable(msg.sender).transfer(rewards);
        uint256 tokenUser = CurrentUser.tokenLoan;
         _burn(msg.sender, tokenUser );
        CurrentUser.collaterale = 0;
        CurrentUser.amountLoan = 0;
        CurrentUser.hasloan = false;
        emit liquidate(msg.sender, _address);
    }

    receive() external payable {
        emit receiveTransac(msg.sender, msg.value);
    }

    fallback() external payable {
        revert("Eror transaction issue, please try again corectly");
    }

    function getBalance() public onlyOwner nonReentrant {
        require(address(this).balance >= 0, "no found to transfert Boss");
        payable(msg.sender).transfer(address(this).balance);
    }
}