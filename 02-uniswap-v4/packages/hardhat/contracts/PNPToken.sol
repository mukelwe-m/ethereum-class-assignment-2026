contract PNPToken {}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title PNPToken
/// @notice ERC20 token representing Pick n Pay points with symbol PNPT
contract PNPToken is ERC20 {
    /**
     * @notice Deploys the PNPToken contract
     * @param initialSupply The initial ERC20 supply to mint to the deployer
     *
     * Default ERC20 decimals is 18.
     */
    constructor(uint256 initialSupply) ERC20("PNP Token", "PNPT") {
        _mint(msg.sender, initialSupply);
    }
}
