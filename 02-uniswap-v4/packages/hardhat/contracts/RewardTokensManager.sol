// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { IHooks } from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { PoolId, PoolIdLibrary } from "@uniswap/v4-core/src/types/PoolId.sol";
import { StateLibrary } from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import { TickMath } from "@uniswap/v4-core/src/libraries/TickMath.sol";
import { FixedPoint96 } from "@uniswap/v4-core/src/libraries/FixedPoint96.sol";
import { LiquidityAmounts } from "@uniswap/v4-periphery/src/libraries/LiquidityAmounts.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import { IPositionManager } from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";

interface IHasPermit2 {
    function permit2() external view returns (address);
}

contract RewardTokensManager is Ownable {
    // REQUIRED: Fee tier 0.3% (3000 bips), tick spacing 60, and no hooks
    uint24 public constant FEE_TIER = 3000;
    int24 public constant TICK_SPACING = 60;
    address public constant HOOKS = address(0);

    IPoolManager public immutable poolManager;
    IPositionManager public immutable positionManager;
    IERC20 public immutable pnpToken;
    IERC20 public immutable fnbToken;
    address public immutable permit2;

    PoolId public poolId;
    mapping(PoolId => bool) public createdPools;

    // TODO REQUIREMENT: Dedicated event emitted when a pool is successfully initialized
    event PoolCreated(
        bytes32 indexed poolId,
        address indexed currency0,
        address indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        address hooks,
        uint160 sqrtPriceX96
    );

    // TODO REQUIREMENT: Dedicated event emitted when a liquidity position is minted
    event LiquidityMinted(
        bytes32 indexed poolId,
        uint256 indexed positionId,
        address owner,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    );

    error TickRangeDoesNotCoverAssignmentPrice();
    error InvalidTickRange();
    error InvalidMintAmounts();
    error PoolNotCreated();
    error PoolAlreadyCreated();

    // TODO REQUIREMENT: Constructor receives the base pool manager and token addresses
    constructor(
        address _poolManager,
        address _positionManager,
        address _pnpToken,
        address _fnbToken
    ) Ownable(msg.sender) {
        poolManager = IPoolManager(_poolManager);
        positionManager = IPositionManager(_positionManager);
        pnpToken = IERC20(_pnpToken);
        fnbToken = IERC20(_fnbToken);

        // Safely extract the internal Permit2 address used by the PositionManager
        try IHasPermit2(_positionManager).permit2() returns (address p2) {
            permit2 = p2;
        } catch {
            permit2 = address(0);
        }
    }

    /// @notice Returns token addresses sorted in canonical order (lower address first)
    /// @dev Required because Uniswap v4 pools always require sorted asset pairs
    function getCanonicalCurrencies() public view returns (address currency0, address currency1) {
        if (address(pnpToken) < address(fnbToken)) {
            return (address(pnpToken), address(fnbToken));
        }
        return (address(fnbToken), address(pnpToken));
    }

    /// @notice Calculates the target tick where the pool price perfectly equals 1 FNBT = 10 PNPT
    /// @dev Maps back to the assignment ratio using the math formula: price = currency0 / currency1
    function getTargetTick() public view returns (int24) {
        (address currency0, ) = getCanonicalCurrencies();
        bool currency0IsPnp = currency0 == address(pnpToken);
        uint160 assignmentSqrtPriceX96 = _getAssignmentSqrtPriceX96(currency0IsPnp);
        return TickMath.getTickAtSqrtPrice(assignmentSqrtPriceX96);
    }

    /// @notice Returns the active pool identifier as a raw bytes32 blob
    function getPoolId() public view returns (bytes32) {
        return PoolId.unwrap(poolId);
    }

    // TODO REQUIREMENT: Initialize the pool through the v4 PoolManager
    // @dev onlyOwner modifier ensures only the deployment admin can trigger pool registration
    function createPool(uint160 sqrtPriceX96) external onlyOwner returns (bytes32) {
        if (PoolId.unwrap(poolId) != bytes32(0)) revert PoolAlreadyCreated();

        // Assemble the structure payload for the target market
        PoolKey memory key = _getPoolKey();

        // Execute the call to register the market on-chain
        poolManager.initialize(key, sqrtPriceX96);

        PoolId createdPoolId = key.toId();
        poolId = createdPoolId;
        createdPools[createdPoolId] = true;

        // TODO REQUIREMENT: Emit the explicit pool creation event details
        emit PoolCreated(
            PoolId.unwrap(createdPoolId),
            Currency.unwrap(key.currency0),
            Currency.unwrap(key.currency1),
            FEE_TIER,
            TICK_SPACING,
            HOOKS,
            sqrtPriceX96
        );
        return PoolId.unwrap(createdPoolId);
    }

    /// @notice Mints concentrated liquidity into the active Uniswap v4 pool
    function mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 positionId, bytes32 poolId_) {
        // TODO REQUIREMENT (1): Validate user inputs and tick alignment bounds
        if (amount0Desired == 0 && amount1Desired == 0) revert InvalidMintAmounts();
        if (tickLower >= tickUpper) revert InvalidTickRange();
        if (tickLower % TICK_SPACING != 0 || tickUpper % TICK_SPACING != 0) revert InvalidTickRange();
        if (tickLower < TickMath.minUsableTick(TICK_SPACING) || tickUpper > TickMath.maxUsableTick(TICK_SPACING))
            revert InvalidTickRange();

        // TODO REQUIREMENT (2): Ensure the user's tick bounds include the 1 FNBT = 10 PNPT target price
        int24 targetTick = getTargetTick();
        if (tickLower > targetTick || tickUpper < targetTick) revert TickRangeDoesNotCoverAssignmentPrice();

        // TODO REQUIREMENT (3): Resolve and verify the unique poolId from the key mapping
        PoolId createdPoolId = poolId;
        if (PoolId.unwrap(createdPoolId) == bytes32(0) || !createdPools[createdPoolId]) revert PoolNotCreated();

        PoolKey memory key = _getPoolKey();
        PoolId resolvedPoolId = key.toId();
        if (PoolId.unwrap(resolvedPoolId) != PoolId.unwrap(createdPoolId)) revert PoolNotCreated();

        // TODO REQUIREMENT (4): Compute liquidity amounts based on current pool price parameters
        (uint160 sqrtPriceX96, , , ) = StateLibrary.getSlot0(poolManager, resolvedPoolId);
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            amount0Desired,
            amount1Desired
        );

        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);

        // TODO REQUIREMENT (5): Pull the required funding amounts from the user wallet
        // TODO REQUIREMENT (6): Approve Permit2 so PositionManager can settle the token balances
        if (amount0Desired > 0) {
            IERC20(token0).transferFrom(msg.sender, address(this), amount0Desired);
            IERC20(token0).approve(address(positionManager), type(uint256).max);
            if (permit2 != address(0)) IERC20(token0).approve(permit2, type(uint256).max);
        }
        if (amount1Desired > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), amount1Desired);
            IERC20(token1).approve(address(positionManager), type(uint256).max);
            if (permit2 != address(0)) IERC20(token1).approve(permit2, type(uint256).max);
        }

        // TODO REQUIREMENT (7): Encode multi-call operations for position management router
        positionId = positionManager.nextTokenId();

        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(
            key,
            tickLower,
            tickUpper,
            liquidity,
            uint128(amount0Desired),
            uint128(amount1Desired),
            msg.sender,
            bytes("")
        );
        params[1] = abi.encode(key.currency0, key.currency1);

        positionManager.modifyLiquidities(abi.encode(actions, params), block.timestamp + 1 hours);

        // TODO REQUIREMENT (8): Verification is implicit as any downstream failures revert the transaction frame

        // TODO REQUIREMENT (9): Return any unspent token dust to the sender and emit assignment event
        _refundDust(token0);
        _refundDust(token1);

        emit LiquidityMinted(PoolId.unwrap(resolvedPoolId), positionId, msg.sender, tickLower, tickUpper, liquidity);
        return (positionId, PoolId.unwrap(resolvedPoolId));
    }

    /// @notice Builds the configuration key object for the liquidity pool structure
    function _getPoolKey() internal view returns (PoolKey memory) {
        (address currency0, address currency1) = getCanonicalCurrencies();
        return
            PoolKey({
                currency0: Currency.wrap(currency0),
                currency1: Currency.wrap(currency1),
                fee: FEE_TIER,
                tickSpacing: TICK_SPACING,
                hooks: IHooks(HOOKS)
            });
    }

    /// @notice Transfers remaining contract tokens back to the transaction caller
    function _refundDust(address token) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(msg.sender, balance);
        }
    }

    /// @notice Internal square-root price calculator for target math validation
    function _getAssignmentSqrtPriceX96(bool currency0IsPnp) internal pure returns (uint160) {
        uint256 numerator = currency0IsPnp ? 1 : 10;
        uint256 denominator = currency0IsPnp ? 10 : 1;
        uint256 priceQ192 = (numerator * (uint256(FixedPoint96.Q96) ** 2)) / denominator;
        return _sqrt(priceQ192);
    }

    /// @notice Pure integer square root helper for gas efficiency
    function _sqrt(uint256 value) internal pure returns (uint160 result) {
        if (value == 0) return 0;
        uint256 x = value;
        uint256 y = 1 << 128;
        while (y > x) {
            y >>= 1;
        }
        for (uint256 i = 0; i < 7; ++i) {
            y = (y + x / y) >> 1;
        }
        result = uint160(y);
        uint256 result256 = uint256(result);
        if (result256 * result256 > value) {
            result = uint160(result256 - 1);
        }
    }
}
