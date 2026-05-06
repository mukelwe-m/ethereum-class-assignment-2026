# ERC20 Tokens

During the tutorials we went through the [ERC-721](https://github.com/ethereum/ercs/blob/master/ERCS/erc-721.md) standard for Non Fungible Tokens. Any smart contract that implements this standard can mint (create) tokens that are unique. For this assignment we will look at the [ERC-20](https://github.com/ethereum/ERCs/blob/master/ERCS/erc-20.md) standard. Any smart contract that implements this standard can mint tokens that are fungible meaning each token is identical in value and function to all others of the same type. ERC20 is the most common token standard on Ethereum. It defines how fungible tokens behave so wallets, exchanges, and smart contracts can all interact with them consistently.

## What You Should Understand

- **Fungibility**: each token unit has the same value and can be exchanged 1:1.
- **Supply model**: fixed supply vs mintable/burnable supply.
- **Decimals**: token precision (for example, 18 decimals means values are stored in smallest units).
- **Balances**: mapping of account address to token amount.
- **Allowances**: an owner can approve a spender to move tokens on their behalf.

### Fungibility

ERC-20 tokens are designed to be fungible, meaning one token is equivalent to another. The ERC-20 standard on the Ethereum blockchain is used by smart contracts to define the properties of the token, such as its name, symbol, and supply, as well as the rules for transferring tokens between accounts.

The ERC-20 standard promotes interoperability by providing a standardized API for tokens, making it easier to integrate them with other products and services, such as wallets and exchanges. ERC-20 smart contracts are used when creating tokens that will be used as Currency or Utility Tokens.

For example, PicknPay could put their smart shopper points (PNP) program on the blockchain. This would mean shoppers with the PNP can trade them for other crypto currencies such as ETH (WETH if traded on a DEX like Uniswap). Depending on the demand for PNP, it's price relative to other crypto currencies might increase which could be an incentive for PicknPay to put their PNP on the blockchain.

### Supply model

Supply model refers to how token supply is created, managed, and potentially reduced over time. In a fixed-supply ERC20, all tokens are created once (usually at deployment), and no new tokens can be minted later. In mintable/burnable models, authorized addresses can increase supply by minting or decrease supply by burning.

This matters because supply mechanics influence scarcity, governance, and trust in the token. Before using a token in a trading system, you should know whether supply can change and who controls that ability.

### Decimals

ERC20 tokens use integers internally, not floating-point numbers. The `decimals` value tells wallets and applications how to interpret those integers for human-readable display. For example, if `decimals` is `18`, then `1` token is represented as `1000000000000000000` units on-chain.

Understanding decimals is essential when writing smart contracts and tests, because order sizes, prices, and balances must use base units. Most mistakes in token math come from mixing display values with raw on-chain values.

### Balances

ERC20 contracts track how many tokens each address owns through internal balance mappings. When a transfer occurs, the sender balance decreases and the receiver balance increases in the same transaction. If a transfer would make the sender balance negative, the transaction reverts.

Balance tracking is foundational for trading logic. In an order book, you need to verify users actually have enough token balance before settlement, and ensure balances update correctly after each matched trade.

### Allowances

Allowances allow one address to authorize another address to spend tokens on its behalf. The owner calls `approve(spender, amount)`, and the spender later uses `transferFrom(owner, recipient, amount)` up to that approved limit. This is the standard way DEX contracts move user tokens during trades.

The allowance model separates permission from execution, which improves flexibility but requires careful handling. In your assignment, understanding allowances is critical because the order book contract will not hold user private keys and must rely on explicit token approvals.

## Core ERC20 Functions

- `totalSupply()`: returns total existing token units.
- `balanceOf(address)`: returns an account's balance.
- `transfer(address to, uint256 amount)`: moves tokens from sender to recipient.
- `approve(address spender, uint256 amount)`: sets spender allowance.
- `allowance(address owner, address spender)`: checks approved amount.
- `transferFrom(address from, address to, uint256 amount)`: transfers using allowance.

## Core Events

- `Transfer(address indexed from, address indexed to, uint256 value)`
- `Approval(address indexed owner, address indexed spender, uint256 value)`

## Why It Matters for This Assignment

Your order book will trade ERC20 tokens. If you understand token balances, approvals, and `transferFrom`, it becomes clear how a trading contract can safely move tokens between users.
