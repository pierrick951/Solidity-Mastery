// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CurveSwap {
    uint256 public constant A = 100;  // Constante pour ajuster la "stabilité" de la courbe
    uint256 public constant FEE = 3;  // Frais sur les swaps (exprimé en pourcentage)
    
    mapping(address => uint256) public balances;
    
    address public stablecoin1;
    address public stablecoin2;

    constructor(address _stablecoin1, address _stablecoin2) {
        stablecoin1 = _stablecoin1;
        stablecoin2 = _stablecoin2;
    }

    function deposit(address token, uint256 amount) public {
        require(token == stablecoin1 || token == stablecoin2, "Token invalide");
        balances[token] += amount;
    }

    // Fonction pour calculer la sortie du swap avec moins de slippage
    function getDy(
        uint256 x,  // Réserve de token dans le pool
        uint256 y,  // Réserve du token opposé
        uint256 dx  // Quantité à échanger
    ) public pure returns (uint256 dy) {
        uint256 xAdjusted = x + dx * A;  // Ajuste en fonction de la constante de stabilité
        uint256 yAdjusted = y - (y * dx) / xAdjusted;  // Formule simplifiée de Curve pour réduire le slippage
        dy = yAdjusted;
    }

    // Swap stablecoin1 contre stablecoin2
    function swap(uint256 amountIn, address fromToken, address toToken) public returns (uint256) {
        require(fromToken == stablecoin1 || fromToken == stablecoin2, "Token invalide");
        require(toToken == stablecoin1 || toToken == stablecoin2, "Token invalide");
        require(fromToken != toToken, "Les tokens doivent etre differents");

        // Simule l'échange
        uint256 reserveFrom = balances[fromToken];
        uint256 reserveTo = balances[toToken];
        
        uint256 amountOut = getDy(reserveFrom, reserveTo, amountIn);
        
        // Appliquer les frais
        uint256 fee = (amountOut * FEE) / 100;
        amountOut -= fee;

        // Mettre à jour les réserves
        balances[fromToken] += amountIn;
        balances[toToken] -= amountOut;

        return amountOut;
    }
}
