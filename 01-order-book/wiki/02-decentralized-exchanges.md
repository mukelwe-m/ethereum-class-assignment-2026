# Decentralized Exchanges

A decentralized exchange (DEX) like Uniswap or Coinbase is a platform that allows users to trade cryptocurrencies directly with each other, without relying on a centralized intermediary (like Binance or Coinbase). These transactions are facilitated by smart contracts when certain conditions are met. Here is an artilce on [cointelegraph](https://cointelegraph.com/learn/articles/what-are-decentralized-exchanges-and-how-do-dexs-work) to understand DEXs more. There are different models for a DEX as shown in the image below.

<div align="center">
<img width="763" alt="image" src="https://github.com/user-attachments/assets/9ba6760f-b119-4602-a98b-0244c4275b1e" />
</div>

## What You Should Understand

- **DEX vs CEX**: users keep wallet control and authorize contract actions.
- **On-chain settlement**: trade execution and settlement happen on-chain.
- **Liquidity**: markets need buy/sell interest for efficient trading.
- **Pricing models**: order book model vs automated market maker (AMM) model.

### DEX vs CEX

A centralized exchange (CEX) is operated by a company that controls user accounts, order matching, and custody of funds inside its platform. A decentralized exchange (DEX) uses smart contracts so users can trade directly from their wallets without handing over custody to a central operator.

This difference affects trust assumptions and user responsibility. On a DEX, users control their own private keys and approve contract interactions explicitly, which aligns with the non-custodial nature of blockchain systems.

### On-chain settlement

On-chain settlement means trade execution and final ownership updates happen on the blockchain itself. When a trade is matched, token transfers are performed by smart contract logic in a transaction that is publicly verifiable and immutable once confirmed.

This is important because settlement guarantees and transparency come from the chain, not from a private company database. For your assignment, this is the reason token movements must be encoded in contract functions and tested carefully.

### Liquidity

Liquidity refers to how easily traders can buy or sell an asset without causing a large price change. In order book markets, liquidity comes from participants placing enough buy and sell orders across price levels.

Higher liquidity generally leads to tighter spreads and faster execution, while low liquidity causes slippage and unfilled orders. Understanding liquidity helps you reason about why some orders fill immediately and others remain open.

### Pricing models

DEXs commonly use either an order book model or an automated market maker (AMM) model. In an order book model, traders specify explicit prices and amounts, and matching logic pairs compatible bids and asks. In an AMM model, users trade against a liquidity pool where pricing is determined by a formula.

The first part of the assignment uses the order book approach. You need to design contract logic around user-submitted orders, price checks, and matching behavior rather than pool-based formulas.

## Order Book DEX Basics

- **Buy order (bid)**: intent to buy a token at a given price.
- **Sell order (ask)**: intent to sell a token at a given price.
- **Matching engine**: logic that pairs compatible buy and sell orders (Usually happens off chain).
- **Partial fills**: an order can be filled in multiple trades.
- **Order status**: open, partially filled, filled, or canceled.

### Buy order (bid)

A buy order (or bid) is an instruction to purchase a specific amount of a token at a given price or better. In an order book, buy orders represent demand and are usually sorted by highest price first so the best buyer is matched first.

For your assignment, each buy order should clearly capture trader address, amount, and price so matching logic can compare it against available sell orders.

### Sell order (ask)

A sell order (or ask) is an instruction to sell a specific amount of a token at a given price or better. Sell orders represent supply and are commonly sorted by lowest price first so the best seller can be matched first.

Correctly storing sell order details is essential for fair and predictable matching. Your contract should be able to compare asks against incoming bids based on compatible price and remaining amount.

### Matching engine

The matching engine is the set of rules that determines when a buy order and a sell order are compatible and should execute. At minimum, it checks whether bid price is greater than or equal to ask price and computes how much of each order can be filled.

In a smart contract order book, this matching logic must be deterministic and secure. It should prevent double fills, update remaining quantities correctly, and transfer tokens atomically as trades execute.

### Partial fills

A partial fill happens when one order is larger than its current match, so only part of the order is executed in a single trade. The remainder stays open and can be matched by future orders.

Partial fills are common in real markets and are important to model correctly. Your order book should track filled amount versus remaining amount so users can see how much of an order is still active.

### Order status

Order status describes the lifecycle state of each order as matching progresses. Typical states are open, partially filled, fully filled, and canceled.

Clear status handling improves both correctness and user visibility. In your assignment, status updates should align with fill calculations and event emissions so off-chain apps can reconstruct market activity reliably.

## Security and Design Considerations

- Validate token transfers and allowances carefully.
- Prevent overfilling the same order.
- Handle edge cases like zero amount, invalid price, or insufficient balance.
- Emit clear events for transparency and off-chain indexing.

## Why It Matters for This Assignment

You will build an order book for two ERC20 tokens. Understanding DEX order flow and matching logic will help you design correct contract functions and tests.
