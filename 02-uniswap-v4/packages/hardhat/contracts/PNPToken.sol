// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title PNPToken
/// @notice ERC20 token representing Pick n Pay points with symbol PNPT
contract PNPToken is ERC20 {
    constructor() ERC20("PNP Token", "PNPT") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
