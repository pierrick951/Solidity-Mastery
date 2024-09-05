// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Contrib is Ownable, ReentrancyGuard, ERC20 {
    uint256 supllyToken;
    uint256 priceToken;

    constructor(uint256 _supllyToken)
        ERC20("Optoken", "OTK")
        Ownable(msg.sender)
    {
        _mint(msg.sender, _supllyToken);

        supllyToken = _supllyToken;

    }

    function burnToken(uint256 _burnToken) public onlyOwner {
        _burn(msg.sender, _burnToken);
    }

    struct contributeur {
        uint256 token;
        string contribution;
        uint256 voteContribution;
        uint256 levelContribution;
        uint256 timeContrib;
        bool haveContrib;
    }

    mapping(address => contributeur) public Contributeurs;
    mapping(address => mapping(address => bool)) public votes;

    event _addContrib(address indexed user, string contribution);
    event _addVote(address indexed user, address contributeur);
    event _addDecisiont(address indexed user, string resultat);
    event _receiveEther(address indexed user, uint256 value);

    function addContrib(string memory _lien) public nonReentrant {
        contributeur storage currentContrib = Contributeurs[msg.sender];
        require(
            bytes(currentContrib.contribution).length == 0,
            "You have already a contrib in traitement"
        );
        currentContrib.contribution = _lien;
        currentContrib.haveContrib = true;
        currentContrib.timeContrib = block.timestamp;
        emit _addContrib(msg.sender, _lien);
    }

    function addVote(address _adress) public nonReentrant {
        require(!votes[msg.sender][_adress], "You have already voted for this contribution.");
        require(
            Contributeurs[_adress].haveContrib,
            "this User have no contribution currently"
        );
        votes[msg.sender][_adress]  = true;
        Contributeurs[_adress].voteContribution += 1;
    

        emit _addVote(msg.sender, _adress);
    }

    function decision() public nonReentrant onlyOwner {
        contributeur storage currentContrib = Contributeurs[msg.sender];
        require(
            currentContrib.timeContrib + 1 weeks > block.timestamp,
            "Time done"
        );
        string memory results = currentContrib.voteContribution >= 50
            ? "Aprouved, good job"
            : "next time you got this";

        if (currentContrib.voteContribution >= 50) {
            currentContrib.token += 10;
            currentContrib.levelContribution += 1;
        }

        currentContrib.contribution = "";
        currentContrib.timeContrib = 0;
        currentContrib.haveContrib = false;
        currentContrib.voteContribution = 0;
        emit _addDecisiont(msg.sender, results);
    }

    function getContrib(address _address) public view returns (string memory) {
        require(
            Contributeurs[_address].haveContrib,
            "this User have no contribution currently"
        );
        return Contributeurs[_address].contribution;
    }

    function getMyContrib() public view returns (string memory) {
        require(Contributeurs[msg.sender].haveContrib, "You have not Contrib");
        return Contributeurs[msg.sender].contribution;
    }

    function getMyToken() public view returns (uint256) {
        return Contributeurs[msg.sender].token;
    }

    function getToken(address _address) public view returns (uint256) {
        return Contributeurs[_address].token;
    }

    function getLevel(address _address) public view returns (uint256) {
        return Contributeurs[_address].levelContribution;
    }

    function getMyLevel() public view returns (uint256) {
        return Contributeurs[msg.sender].levelContribution;
    }

    function getVote(address _user, address _contributeur) public view returns (bool) {
        return  votes[_user][_contributeur];
    }

    function getMyVote(address _contributeur) public view returns(bool) {
        return  votes[msg.sender][_contributeur];
    }

    receive() external payable {
        emit _receiveEther(msg.sender, msg.value);
    }

    fallback() external payable {
        payable(address(this)).transfer(msg.value);
    }

    function getTransfer() public payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }
}
