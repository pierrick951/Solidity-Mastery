// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;




uint256 feePercent = 3; // Frais de 0.3% (exprimé en pour mille)

// Calcul avec frais
uint256 feeAmount = (_amountIn * feePercent) / 1000;
uint256 amountInAfterFee = _amountIn - feeAmount;