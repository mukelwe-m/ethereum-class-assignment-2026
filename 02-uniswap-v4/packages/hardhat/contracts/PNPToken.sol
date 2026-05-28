// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title PNPToken
/// @notice ERC20 token representing Pick n Pay points with symbol PNPT
contract PNPToken is ERC20 {
    /**
     * @notice Deploys the PNPToken contract and mints the initial supply
     * @param initialSupply The total number of tokens to mint to the deployer account
     * @dev Pass supply with 18 decimal precision (e.g., 1000000000000000000000000 for 1M tokens)
     */
    constructor(uint256 initialSupply) ERC20("PNP Token", "PNPT") {
        // Mint the total token supply directly to the address deploying this contract
        _mint(msg.sender, initialSupply);
    }
}
