contract FNBToken {}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title FNBToken
/// @notice ERC20 token representing FNB eBucks with symbol FNBT
contract FNBToken is ERC20 {
    /**
     * @notice Deploys the FNBToken contract
     * @param initialSupply The initial ERC20 supply to mint to the deployer
     *
     * Default ERC20 decimals is 18.
     */
    constructor() ERC20("FNB Token", "FNBT") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
