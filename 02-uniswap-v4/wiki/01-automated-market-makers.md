# Automated Market Makers

## What You Should Understand

- **Liquidity pools**
- **Pricing curve / invariant**
- **Liquidity providers (LPs)**
- **Slippage**
- **Impermanent Loss**
- **Order book vs AMM**

### Liquidity pools

An **automated market maker** (AMM) is a type of decentralized exchange where trades execute against **liquidity pools** held in smart contracts, instead of against a traditional order book of bids and asks. An AMM uses liquidity pools (LPs) and a formula to determine prices. A LP is simply a smart contract that holds a pair of ERC-20 tokens (on Ethereum). These crypto currencies in the LP are supplied by liquidity providers who make their money from transaction fees when a trade happens in the LP smart contract.

### Pricing curve / invariant

The AMM must make sure that the prices of the 2 tokens in the LP relative to each other are reflective of the market demand and supply. If this is not the case arbitrageurs will take advantage of this such that the price is driven to the correct market price. For example, in a WETH/USDC liquidity pool, we want to make sure if there is more demand for WETH (which means users are draining WETH from the LP smart contract and living it with USDC) the price of WETH in terms of USDC should go up until equilibrium is reached.

Uniswap uses a formula called the Constant Product Formula and AMMs using it are called CPMM (Constant Product Market Makers):

<div align="center" style="font-size: large">
<h2>
𝑥 ⋅ 𝑦 = 𝑘
</h2>
</div>

Where: <br>
x is the amount of Token A in the pool <br>
y is the amount of Token B in the pool <br>
k is a constant (the product of the two) <br>

The resulting graph is shown below. This ensures that as one token is bought, its price increases, and the other decreases—automatically adjusting prices based on supply and demand. When a trade happens the quantities of x and y change but the equation should still hold. 

<div align="center">
<img width="400" alt="image" src="https://github.com/user-attachments/assets/7a64c281-7070-4ece-9623-cde97e42877f" />
<img width="400" alt="image" src="https://github.com/user-attachments/assets/bea00a9d-88e6-4673-9e50-bc15066992a7" />
</div>

<div align="center" style="font-size: large">
<h2>
( 𝑥 + Δ 𝑥 ) ⋅ ( 𝑦 - Δ 𝑦 ) = 𝑘
</h2>
</div>

### Liquidity providers (LPs)

LPs earn a share of trading fees by taking **inventory risk**: if the price of one asset moves, their pool position can be worth less than simply holding the tokens (**impermanent loss** is a common way to describe that risk).

### Slippage

The realized price after a trade is going to be `Δ 𝑥 / Δ 𝑦`. This price is going to be different from the price at which the LP was before the trade `𝑥 / 𝑦`. The difference is more pronounced for very large trades at low liquidity (i.e. when the amounts of the tokens are low). This is a cost to the trader and it is known as `slippage`.

### Impermanent Loss

Impermanent loss happens when token prices diverge from when you deposited liquidity. If one token’s price spikes or dumps, traders/arbitrageurs will rebalance the pool, leaving LPs with more of the underperforming token. The pool can end up drained of one token, especially in volatile pairs. A CPMM avoids drainage of one token for the other because the formula is `asymptotic`.

[Here](https://medium.com/@Knownsec_Blockchain_Lab/in-depth-analysis-of-the-slippage-and-impermanence-loss-of-the-amm-constant-product-model-fb0a86763a25) is a good breakdown of Slippage and Impermanent Loss costs.

### Order book vs AMM

| Order book | AMM |
|------------|-----|
| Explicit limit orders at prices | Implicit price from reserves and curve |
| Matching engine pairs orders | Swaps rebalance the pool along the curve |
| Depth at each price level | Depth from LP deposits and curve shape |

Understanding AMMs is the foundation for **Uniswap v4**, which still implements AMM-style pricing and liquidity, with a new architecture for pools and extensions.

## Further Reading

- [Uniswap docs — concepts](https://docs.uniswap.org/)
