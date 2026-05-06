import { GenericContractsDeclaration } from "~~/utils/scaffold-eth/contract";

/**
 * @example
 * const externalContracts = {
 *   1: {
 *     DAI: {
 *       address: "0x...",
 *       abi: [...],
 *     },
 *   },
 * } as const;
 */
const externalContracts = {} as const;

// Assignment naming reference:
// tokenA => PNPToken (PNPT)
// tokenB => FNBToken (FNBT)
// order book => OrderBook

export default externalContracts satisfies GenericContractsDeclaration;
