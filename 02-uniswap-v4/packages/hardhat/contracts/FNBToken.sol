// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title FNBToken
/// @notice ERC20 token representing FNB eBucks with symbol FNBT
contract FNBToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("FNB Token", "FNBT") {
        _mint(msg.sender, initialSupply);
    }
}
