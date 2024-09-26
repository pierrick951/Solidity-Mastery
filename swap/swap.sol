// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Swap is Ownable, ReentrancyGuard {
    uint256 feePercent = 3;
    address public TokenA;
    address public TokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event Deposit(uint256 _amountA, uint256 _amountB);
    event _Swap(uint256 swap);

    constructor(address _TokenA, address _TokenB) Ownable(msg.sender) {
        TokenA = _TokenA;
        TokenB = _TokenB;
    }

    function addPool(uint256 _reseveA, uint256 _reserveB) public nonReentrant {
        reserveA += _reseveA;
        reserveB += _reserveB;
        emit Deposit(_reseveA, _reserveB);
    }

    function swap(
        address _fromToken,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) public nonReentrant returns (uint256 _amountOut) {
        require(_fromToken == TokenA || _fromToken == TokenB, "invalide Token");
        uint256 AmountAfterFee = _amountIn - addFee(_amountIn);

        if (_fromToken == TokenA) {
            uint256 tokenBOut = calculateSwap(
                reserveB,
                reserveA,
                AmountAfterFee
            );
            require(tokenBOut >= _minAmountOut, "Slippage too high");
            require(tokenBOut > 0, "Insufficient output amount");
            reserveA += _amountIn;
            reserveB -= tokenBOut;

            IERC20(TokenB).transfer(msg.sender, tokenBOut);
            emit _Swap(tokenBOut);
            return tokenBOut;
        } else {
            uint256 TokenAOut = calculateSwap(
                reserveA,
                reserveB,
                AmountAfterFee
            );
              require(TokenAOut >= _minAmountOut, "Slippage too high");
            require(TokenAOut > 0, "insufficient output amount");

            reserveB += _amountIn;
            reserveA -= TokenAOut;

            IERC20(TokenA).transfer(msg.sender, TokenAOut);
            emit _Swap(TokenAOut);
            return TokenAOut;
        }
    }

    function addFee(uint256 _amountFee) private view returns (uint256) {
        return (_amountFee * feePercent) / 100;
    }

    function calculateSwap(
        uint256 _pool1,
        uint256 _pool2,
        uint256 _amountIn
    ) private pure returns (uint256) {
        return (_pool1 * _amountIn) / (_pool2 + _amountIn);
    }

    function getPoolA() public view onlyOwner returns (uint256) {
        return reserveA;
    }

    function getPoolB() public view onlyOwner returns (uint256) {
        return reserveB;
    }
}
