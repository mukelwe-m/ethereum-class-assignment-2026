## Plan: Implement ERC20 Tokens for 01-order-book

TL;DR: Add two standard ERC20 token contracts using OpenZeppelin in `01-order-book/packages/hardhat/contracts`, with constructors that mint an initial supply to the deployer and include comments for all contract logic.

**Steps**
1. Open `01-order-book/packages/hardhat/contracts/PNPToken.sol` and `01-order-book/packages/hardhat/contracts/FNBToken.sol`.
2. Use the template style from `01-order-book/wiki/ERC20-template.txt`:
   - SPDX license header
   - `pragma solidity >=0.8.26 <0.9.0;`
   - import OpenZeppelin `ERC20` from `@openzeppelin/contracts/token/ERC20/ERC20.sol`
   - include comments for contract purpose, constructor, and any logic in the contract
3. Implement `PNPToken` with:
   - name `PNP Token`
   - symbol `PNPT`
   - constructor accepting `uint256 initialSupply`
   - mint initial supply to `msg.sender`
   - comments describing contract purpose and constructor logic
4. Implement `FNBToken` with:
   - name `FNB Token`
   - symbol `FNBT`
   - constructor accepting `uint256 initialSupply`
   - mint initial supply to `msg.sender`
   - comments describing contract purpose and constructor logic
5. Ensure both contracts compile under Solidity 0.8.30 and use the default 18 decimals.

**Relevant files**
- `/Users/mukelwe/Documents/ethereum-class-assignment-2026/01-order-book/packages/hardhat/contracts/PNPToken.sol`
- `/Users/mukelwe/Documents/ethereum-class-assignment-2026/01-order-book/packages/hardhat/contracts/FNBToken.sol`
- `/Users/mukelwe/Documents/ethereum-class-assignment-2026/01-order-book/packages/hardhat/test/AssignmentSolution.ts`

**Verification**
1. `yarn test test/AssignmentSolution.ts` from `01-order-book/packages/hardhat` should pass the Part 1 assertions.
2. Confirm `tokenA.name()` is `PNP Token`, `tokenA.symbol()` is `PNPT`, and `tokenA.totalSupply()` equals the deployed initial supply.
3. Confirm `tokenB.name()` is `FNB Token`, `tokenB.symbol()` is `FNBT`, and `tokenB.totalSupply()` equals the deployed initial supply.
4. Confirm basic ERC20 flow works: `transfer`, `approve`, and `transferFrom`.

**Decisions**
- Use OpenZeppelin ERC20 to satisfy all standard token behavior without custom implementation.
- Keep scope limited to Part 1 token contracts; the OrderBook contract still requires its own implementation for the full test suite.

**Further Considerations**
1. If the goal is to complete the full assignment, the next step after tokens is to implement `OrderBook.sol` according to Part 2 tests.
