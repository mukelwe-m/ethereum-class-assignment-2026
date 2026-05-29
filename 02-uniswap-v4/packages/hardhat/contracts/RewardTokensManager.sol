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

contract RewardTokensManager is Ownable {
    uint24 public constant FEE_TIER = 3000;
    int24 public constant TICK_SPACING = 60;
    address public constant HOOKS = address(0);

    IPoolManager public immutable poolManager;
    IPositionManager public immutable positionManager;
    IERC20 public immutable pnpToken;
    IERC20 public immutable fnbToken;

    PoolId public poolId;
    mapping(PoolId => bool) public createdPools;

    event PoolCreated(
        bytes32 indexed poolId,
        address indexed currency0,
        address indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        address hooks,
        uint160 sqrtPriceX96
    );

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
    }

    /// @notice Returns the canonical token order used by the Uniswap pool key.
    function getCanonicalCurrencies() public view returns (address currency0, address currency1) {
        if (address(pnpToken) < address(fnbToken)) {
            return (address(pnpToken), address(fnbToken));
        }
        return (address(fnbToken), address(pnpToken));
    }

    /// @notice Returns the target tick implied by 1 FNBT = 10 PNPT in the canonical pool order.
    function getTargetTick() public view returns (int24) {
        (address currency0, ) = getCanonicalCurrencies();
        bool priceGreaterThanOne = currency0 == address(pnpToken);
        uint160 assignmentSqrtPriceX96 = _getAssignmentSqrtPriceX96(priceGreaterThanOne);
        return TickMath.getTickAtSqrtPrice(assignmentSqrtPriceX96);
    }

    /// @notice Returns the pool identifier for the currently created pool.
    function getPoolId() public view returns (bytes32) {
        return PoolId.unwrap(poolId);
    }

    /// @notice Creates the Uniswap v4 pool with fee 0.3%, tick spacing 60, and no hooks.
    /// @dev onlyOwner is used because the pool creation flow should be controlled by the deployer in this assignment.
    function createPool(uint160 sqrtPriceX96) external onlyOwner returns (bytes32) {
        if (PoolId.unwrap(poolId) != bytes32(0)) revert PoolAlreadyCreated();

        PoolKey memory key = _getPoolKey();
        poolManager.initialize(key, sqrtPriceX96);

        PoolId createdPoolId = key.toId();
        poolId = createdPoolId;
        createdPools[createdPoolId] = true;

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

    /// @notice Mints a concentrated liquidity position for the current pool.
    /// @dev The caller must approve this contract for both tokens before calling.
    function mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 positionId, bytes32 poolId_) {
        if (amount0Desired == 0 && amount1Desired == 0) revert InvalidMintAmounts();
        if (tickLower >= tickUpper) revert InvalidTickRange();
        if (tickLower % TICK_SPACING != 0 || tickUpper % TICK_SPACING != 0) revert InvalidTickRange();
        if (tickLower < TickMath.minUsableTick(TICK_SPACING) || tickUpper > TickMath.maxUsableTick(TICK_SPACING))
            revert InvalidTickRange();

        int24 targetTick = getTargetTick();
        if (tickLower > targetTick || tickUpper < targetTick) revert TickRangeDoesNotCoverAssignmentPrice();

        PoolId createdPoolId = poolId;
        if (PoolId.unwrap(createdPoolId) == bytes32(0) || !createdPools[createdPoolId]) revert PoolNotCreated();

        PoolKey memory key = _getPoolKey();
        PoolId resolvedPoolId = key.toId();
        if (PoolId.unwrap(resolvedPoolId) != PoolId.unwrap(createdPoolId)) revert PoolNotCreated();

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

        if (amount0Desired > 0) {
            IERC20(token0).transferFrom(msg.sender, address(this), amount0Desired);
            IERC20(token0).approve(address(positionManager), amount0Desired);
        }
        if (amount1Desired > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), amount1Desired);
            IERC20(token1).approve(address(positionManager), amount1Desired);
        }

        positionId = positionManager.nextTokenId();

        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION));
        bytes[] memory params = new bytes[](1);
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

        positionManager.modifyLiquidities(abi.encode(actions, params), block.timestamp + 1 hours);

        _refundDust(token0);
        _refundDust(token1);

        emit LiquidityMinted(PoolId.unwrap(resolvedPoolId), positionId, msg.sender, tickLower, tickUpper, liquidity);
        return (positionId, PoolId.unwrap(resolvedPoolId));
    }

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

    function _refundDust(address token) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(msg.sender, balance);
        }
    }

    function _getAssignmentSqrtPriceX96(bool currency0IsPnp) internal pure returns (uint160) {
        uint256 numerator = currency0IsPnp ? 10 : 1;
        uint256 denominator = currency0IsPnp ? 1 : 10;
        uint256 priceQ192 = (numerator * (uint256(FixedPoint96.Q96) ** 2)) / denominator;
        return _sqrt(priceQ192);
    }

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
        if (result * result > value) {
            result = uint160(result - 1);
        }
    }
}
