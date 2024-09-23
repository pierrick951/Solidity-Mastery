// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface mixem {
    function makeApie(uint32 _sugar, uint32 _timeTocook, string memory _fruits) external;
}

contract Ingredient {
    struct tarte {
        uint32 sugar;
        string fruits;
        uint32 timeTocook;
        uint32 quantityOfPie;
    }

    mapping(address => tarte) Cooking;

    function makeApie(uint32 _sugar, uint32 _timeTocook, string memory _fruits) external {
        tarte storage UserCook = Cooking[msg.sender];
        UserCook.fruits = _fruits;
        UserCook.sugar = _sugar;
        UserCook.timeTocook = _timeTocook;
    }
}

contract recette is Ownable {
    mixem public cookingContract;

    constructor(address _addresIngredients) {
        cookingContract = mixem(_addresIngredients);
    }

    function Cooking(uint32 _sugar, uint32 _timeTocook, string memory _fruits) external {
        cookingContract.makeApie(_sugar, _timeTocook, _fruits);
    }
}
