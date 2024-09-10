// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VaultAdvanced is Ownable, ReentrancyGuard, ERC20 {
    uint256 Totalsuply;
    uint32 PriceToken;
    uint32 rateReward;
    uint32 rateLoan;

    constructor(
        uint32 _priceToken,
        uint256 _suplly
    ) ERC20("Goken", "GKN") Ownable(msg.sender) {
        _mint(msg.sender, _suplly);
        PriceToken = _priceToken;
        Totalsuply = _suplly;
    }

    function BurnToken(uint256 _amount) public onlyOwner {
        _burn(msg.sender, _amount);
    }

    function setrewardRate(uint32 _rate) public onlyOwner {
        rateReward = _rate;
        emit NewRate(msg.sender, _rate);
    }

    function setLoanRate(uint32 _rateLoan) public onlyOwner {
        rateLoan = _rateLoan;
        emit newRateLoan(msg.sender, _rateLoan);
    }

    event Deposite(address indexed users, uint256 depot);
    event ReceiveEther(address indexed users, uint256 _amount);
    event NewRate(address indexed owner, uint32 taux);
    event userReward(address indexed user, uint256 rewards);
    event startLoan(address indexed user, uint256 _amount);
    event newRateLoan(address indexed owner, uint32 _loanRate);
    event liquidation(address indexed author, address indexed _address);
    event LoanRepaid(address indexed user, uint256 _amount);
    struct user {
        uint256 deposite;
        uint256 tokenGovernance;
        uint256 timeStacking;
        uint256 timeLoan;
        uint32 rateUserLoan;
        uint256 SaveAmountLoan;
        bool hasloan;
    }

    mapping(address => user) User;

    function setStacking(uint256 _deposite) public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];

        require(msg.sender.balance >= _deposite, "please retry your deposite");
        CurrentUser.deposite += _deposite;
        CurrentUser.timeStacking = block.timestamp;
        emit Deposite(msg.sender, _deposite);
    }

    function setReward() private nonReentrant {
        user storage CurrentUser = User[msg.sender];
        uint256 rewardTime = CurrentUser.timeStacking - block.timestamp;
        uint256 rewardPeriod = rewardTime / 1 weeks;
        uint256 rewardToken = (rewardPeriod * rateReward) / 100;
        CurrentUser.tokenGovernance += rewardToken;
    }

    function stopVolt() public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(
            CurrentUser.timeStacking + 2 days < block.timestamp,
            "Too early to stop your volt"
        );
        require(
            address(this).balance >= CurrentUser.deposite,
            "Contract doesn't have enough funds"
        );

        CurrentUser.timeStacking = 0;
        payable(address(this)).transfer(CurrentUser.deposite);
        payable(address(this)).transfer(CurrentUser.tokenGovernance);
    }

    function setLoan(uint256 _loan) public nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(!CurrentUser.hasloan, "you have already a loan");
        CurrentUser.hasloan = true;
        CurrentUser.tokenGovernance += _loan;
        CurrentUser.SaveAmountLoan += _loan;
        CurrentUser.timeLoan = block.timestamp;
        uint32 curentRate = uint32(
            (CurrentUser.tokenGovernance * rateLoan) / 100
        );
        CurrentUser.rateUserLoan = curentRate;
        emit startLoan(msg.sender, _loan);
    }

    function refundLoan(uint256 _amount) public payable nonReentrant {
        user storage CurrentUser = User[msg.sender];
        require(CurrentUser.hasloan, "You dont have a loan");
        uint256 timeElapsed = block.timestamp - CurrentUser.timeLoan;
        uint256 interest = (CurrentUser.SaveAmountLoan *
            rateLoan *
            timeElapsed) / (30 days * 100);
        uint256 totalRepayment = CurrentUser.SaveAmountLoan + interest;
        require(
            _amount >= totalRepayment,
            "Amount is less than the total repayment"
        );
        payable(address(this)).transfer(totalRepayment);
        CurrentUser.timeLoan = 0;
        CurrentUser.hasloan = false;

        CurrentUser.SaveAmountLoan = 0;
        emit LoanRepaid(msg.sender, _amount);
    }

    function getLiquidate(address _address) public payable nonReentrant {
        user storage CurrentUser = User[_address];

        uint256 collateralRatio = getRateUser(_address);
        require(collateralRatio < 150, "Le ratio de collateral est suffisant");
        payable(address(this)).transfer(CurrentUser.tokenGovernance);
        payable(address(this)).transfer(CurrentUser.deposite);
        User[msg.sender].tokenGovernance += 50;
        CurrentUser.hasloan = false;
        CurrentUser.timeLoan = 0;
        CurrentUser.rateUserLoan = 0;
        CurrentUser.SaveAmountLoan = 0;

        emit liquidation(msg.sender, _address);
    }

    function getReward() public view returns (uint256) {
        return User[msg.sender].tokenGovernance;
    }

    function getRate() public view returns (uint32) {
        return rateReward;
    }

    function getRateLoan(address _user) public view returns (uint256) {
        user storage CurrentUser = User[_user];
        if (CurrentUser.SaveAmountLoan == 0) {
            return type(uint256).max;
        }
        return rateLoan;
    }

    function getRateUser(address _adress) public view returns (uint32) {
        return User[_adress].rateUserLoan;
    }

    receive() external payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

    fallback() external payable {
        user storage CurrentUser = User[msg.sender];
        require(msg.sender.balance >= msg.value, "please retry your deposite");
        CurrentUser.deposite += msg.value;
        CurrentUser.timeStacking = block.timestamp;
        emit Deposite(msg.sender, msg.value);
    }
}
