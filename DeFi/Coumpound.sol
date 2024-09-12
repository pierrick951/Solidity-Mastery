// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Coumpound is ERC20, Ownable, ReentrancyGuard {
    uint256 SupplyToken;
    uint256 PriceToken;

    uint256 ratioToken = 1 ether;
    uint256 borrow = 70;

    constructor(uint256 _suplly, uint256 _price)
        ERC20("Tokpom", "TKP")
        Ownable(msg.sender)
    {
        _mint(msg.sender, _suplly);

        SupplyToken = _suplly;
        PriceToken = _price;
    }

    function burnToken(uint256 _amount) public onlyOwner {
        _burn(msg.sender, _amount);
    }

    struct user {
        uint256 token;
        uint256 collateral;
        uint256 amountLoan;
        bool hasloan;
    }

    mapping(address => user) User;

    event _buytoken(address indexed user, uint256 amount);
    event _deposite(address indexed user, uint256 amount);
    event _loan(address indexed user, uint256 amount);
    event _refund(address indexed user, uint256 amount);
    event _liquidate(address indexed user, address indexed userliquidate);
    event _receiveFound(address indexed user, uint256 value);

    function buyToken(uint256 _amount) public payable nonReentrant {
        require(msg.value > _amount * PriceToken,"Not enough Ether provided");
        _transfer(address(this), msg.sender, _amount);
        emit _buytoken(msg.sender, _amount);
    }

    function setdeposite(uint256 _amount) public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(CurrentUser.token >= _amount, "You dont necessary found");
        uint256 requiredCollateral = ratioToken * _amount;

        CurrentUser.collateral += requiredCollateral;
        emit _deposite(msg.sender, _amount);
    }

    function getLoan(uint256 _amountLoan) public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(!CurrentUser.hasloan, "You have already a active loan");
        uint256 requiredLoanCollateral = (_amountLoan * borrow) / 100; // si l'user demande 30 ether il devra mettre 100 token en collateral ?
        require(
            CurrentUser.collateral >= requiredLoanCollateral,
            "Insufficient collateral"
        );

        CurrentUser.hasloan = true;
        CurrentUser.amountLoan += _amountLoan;
        emit _loan(msg.sender, _amountLoan);
    }

    function refund(uint256 _loanRefund) public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        uint256 CurrentUserLoan = User[msg.sender].amountLoan;

        require(CurrentUser.hasloan, "You don't have any loan to refund");
        uint256 interest = (CurrentUserLoan * 5) / 100;
        uint256 totalRefund = CurrentUserLoan + interest;
        require(
            _loanRefund >= totalRefund,
            "Amount is less than the total repayment"
        );
        payable(address(this)).transfer(totalRefund);

        CurrentUser.hasloan = false;
        CurrentUser.amountLoan = 0;
        _burn(msg.sender, CurrentUser.collateral);
        emit _refund(msg.sender, _loanRefund);
    }

    function liquidate() public payable onlyOwner nonReentrant {
        user storage CurrentUser = User[msg.sender];
      
        require( (CurrentUser.collateral * 100) / CurrentUser.amountLoan < 120, "Collateralization ratio is above the liquidation threshold");
        payable(address(this)).transfer(CurrentUser.collateral);
        CurrentUser.hasloan = false;
        _burn(msg.sender, CurrentUser.collateral);
    }

    receive() external payable nonReentrant {
        emit _receiveFound(msg.sender, msg.value);
    }

    fallback() external payable onlyOwner nonReentrant {
       emit _receiveFound(msg.sender, msg.value);
       payable(msg.sender).transfer(msg.value);
       revert("Function not found or invalid call.");
    }

    function getFound() public payable onlyOwner nonReentrant {
        require(address(this).balance >= 0 , "No found to tranfer Boss");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getCollateralRatio() public view returns (uint256) {
        uint256 ActualColateral = (User[msg.sender].collateral * borrow) / 100;
        return ActualColateral;
    }
}
