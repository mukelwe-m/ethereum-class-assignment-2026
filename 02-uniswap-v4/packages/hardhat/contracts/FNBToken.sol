// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title FNBToken
/// @notice ERC20 token representing FNB eBucks with symbol FNBT
contract FNBToken is ERC20 {
    constructor() ERC20("FNB Token", "FNBT") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
