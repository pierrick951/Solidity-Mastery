// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap {
    address public TokenA;
    address public TokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    constructor(address _tokenA, address _tokenB) {
        TokenA = _tokenA;
        TokenB = _tokenB;
    }

    function addLiquidity(uint256 _reserveA, uint256 _reserveB) public {
        // Ajouter de la liquidité au pool
        reserveA += _reserveA;
        reserveB += _reserveB;

        // Transférer les tokens de l'utilisateur vers ce contrat
        IERC20(TokenA).transferFrom(msg.sender, address(this), _reserveA);
        IERC20(TokenB).transferFrom(msg.sender, address(this), _reserveB);
    }

    function swap(address _fromToken, uint256 _amountIn) public returns (uint256 _amountOut) {
        require(_fromToken == TokenA || _fromToken == TokenB, "invalid Token");

        if (_fromToken == TokenA) {
            uint256 tokenBOut = (reserveB * _amountIn) / (reserveA + _amountIn);
            require(tokenBOut > 0, "Insufficient output amount");
            reserveA += _amountIn;
            reserveB -= tokenBOut;

            // Transférer le montant de TokenB à l'utilisateur
            IERC20(TokenB).transfer(msg.sender, tokenBOut);
            return tokenBOut;
        } else {
            uint256 tokenAOut = (reserveA * _amountIn) / (reserveB + _amountIn);
            require(tokenAOut > 0, "Insufficient output amount");
            reserveB += _amountIn;
            reserveA -= tokenAOut;

            // Transférer le montant de TokenA à l'utilisateur
            IERC20(TokenA).transfer(msg.sender, tokenAOut);
            return tokenAOut;
        }
    }
}
