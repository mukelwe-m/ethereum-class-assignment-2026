# Ethereum Class Assignment 2026

This repository contains the class assignments for the Fintech and Cryptocurrency course `ECO5037W`.

## Assignment Folders

- `01-order-book/`: build ERC20 tokens and an order book DEX.
- `02-uniswap-v4/`: build reward-token market infrastructure using Uniswap v4 concepts.

## 01: Order Book Assignment

In `01-order-book/`, use the wiki as your study and implementation guide:

- `01-order-book/wiki/README.md`
- `01-order-book/wiki/01-erc20-tokens.md`
- `01-order-book/wiki/02-decentralized-exchanges.md`
- `01-order-book/wiki/03-assignment.md`

Assignment focus:
- Create `PNPToken` (`PNPT`) and `FNBToken` (`FNBT`) ERC20 contracts.
- Build an order book contract to trade these reward tokens.

## 02: Uniswap v4 Assignment

In `02-uniswap-v4/`, use the wiki as your study and implementation guide:

- `02-uniswap-v4/wiki/README.md`
- `02-uniswap-v4/wiki/01-automated-market-makers.md`
- `02-uniswap-v4/wiki/02-uniswap-v4.md`
- `02-uniswap-v4/wiki/03-assignment.md`

Assignment focus:
- Install and use `@uniswap/v4-core`.
- Create and initialize a pool via `PoolManager` for `PNPT`/`FNBT`.
- Mint a liquidity position in the configured fee tier and tick spacing.
