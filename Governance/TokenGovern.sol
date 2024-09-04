// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Gouvernance is Ownable, ReentrancyGuard, ERC20 {
    uint256 supplyToken;
    uint256 priceToken;
    uint256 immutable tokenVote = 2;
    uint256 numberVote = 0;

    constructor(uint256 _supllyToken, uint256 _priceToken)
        ERC20("TokenVote", "TKV")
        Ownable(msg.sender)
    {
        _mint(msg.sender, _supllyToken);
        supplyToken = _supllyToken;
        priceToken = _priceToken;
    }

    event _buyToken(address indexed user, uint256 amount);
    event _makeADecision(address indexed user, string);
    event _endAdecision(address indexed user, string decider);
    event _receiveEther(address indexed user, uint256 value);
    event _voted(address indexed user);

    function burnToken(uint256 _burnToken) public onlyOwner {
        _burn(msg.sender, _burnToken);
    }

    struct user {
        uint256 votes;
        uint256 token;
        string decision;
        uint256 votePositif;
        uint256 voteNegatif;
        uint256 TimeToVote;
        bool haveDecision;
    }

    mapping(address => user) Users;

    function buyToken(uint256 _amount) public payable nonReentrant {
        require(_amount <= supplyToken, "Amount exceeds supply");
        require(supplyToken > 0, "no tickets avaible");
        require(msg.value >= _amount * priceToken, "insufisant found");
        Users[msg.sender].token += _amount;
        supplyToken -= _amount;
        emit _buyToken(msg.sender, _amount);
    }

    function MakeADecision(string memory _decision)
        public
        payable
        nonReentrant
    {
        user storage currentUser = Users[msg.sender];

        string memory userDecision = currentUser.decision;
        require(
            currentUser.token >= 500,
            "You need more token for make a decision"
        );
        require(
            bytes(userDecision).length == 0,
            "You already have a running decision"
        );
        currentUser.decision = _decision;
        currentUser.TimeToVote = block.timestamp;
        currentUser.haveDecision = true;
    }

    function endAdecision() public onlyOwner {
        user storage currentUser = Users[msg.sender];
        require(
            currentUser.TimeToVote + 2 weeks > block.timestamp,
            "Time done"
        );

       string memory result = currentUser.votePositif > currentUser.voteNegatif
        ? "Decision accepted"
        : "Decision not accepted";

        currentUser.decision = "";
        currentUser.TimeToVote = 0;
        currentUser.voteNegatif = 0;
        currentUser.votePositif = 0;
        emit _endAdecision(msg.sender, result);
    }

    function voteYes(address _decision) public payable nonReentrant {
        user storage currentUser = Users[msg.sender];
        require(currentUser.token > msg.value);
        require(currentUser.votes > 0, "You have already voted");
        require(
            Users[_decision].haveDecision,
            "this adress have no have active decition"
        );
        uint256 Vote = msg.value * tokenVote;
        Users[_decision].votePositif += Vote;
        currentUser.votes++;
        currentUser.token -= msg.value;
        emit _voted(msg.sender);
    }

    function voteNo(address _decision) public payable nonReentrant {
        user storage currentUser = Users[msg.sender];
        require(currentUser.token > msg.value);
        require(currentUser.votes > 0, "You have already voted");
        uint256 Vote = msg.value * tokenVote;
        Users[_decision].voteNegatif += Vote;
        currentUser.votes++;
        currentUser.token -= msg.value;
        emit _voted(msg.sender);
    }

    receive() external payable {
        emit _receiveEther(msg.sender, msg.value);
    }

    fallback() external payable {
        revert("function not found, transction done");
    }
}
