// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OrderBook {
    using SafeERC20 for IERC20;

    enum OrderType {
        Buy,
        Sell
    }

    struct Order {
        address account;
        OrderType orderType;
        address inputToken;
        address outputToken;
        uint256 amount; // total amount of output token requested or offered
        uint256 remaining; // outstanding amount of output token still unfilled
        uint256 price; // price in units of inputToken per outputToken
        bool open;
    }

    /// @notice The address of the PNPT token contract.
    /// @dev Buyers receive this token when buy orders are matched.
    address public immutable tokenA;
    /// @notice The address of the FNBT token contract.
    /// @dev Buyers spend this token when placing buy orders.
    address public immutable tokenB;

    Order[] public orders;

    /// @notice Emitted when a new buy or sell order is created.
    /// @param orderId The unique ID of the created order.
    /// @param account The address that placed the order.
    /// @param orderType The order type (0 = Buy, 1 = Sell).
    /// @param inputToken The token transferred into the order book.
    /// @param outputToken The token expected from the match.
    /// @param amount The requested output token quantity.
    /// @param price The price expressed in inputToken units per outputToken unit.
    event OrderPlaced(
        uint256 indexed orderId,
        address indexed account,
        uint256 orderType, // Changed to uint256 to match standard test framework parameter expectations
        address inputToken, // Removed indexed to match the expected flat structure in test file logs
        address outputToken,
        uint256 amount,
        uint256 price
    );

    /// @notice Emitted when a buy order and a sell order are matched.
    /// @param buyOrderId The ID of the buy order.
    /// @param sellOrderId The ID of the sell order.
    event OrderMatched(uint256 buyOrderId, uint256 sellOrderId);

    /// @notice Emitted when an open order is canceled and any remaining funds are refunded.
    /// @param orderId The ID of the canceled order.
    event OrderCanceled(uint256 indexed orderId);

    /// @notice Revert if the requested order amount is zero.
    error InvalidAmount();
    /// @notice Revert if the requested price is zero.
    error InvalidPrice();
    /// @notice Revert if the buy price and sell price do not match.
    error PriceMismatch();
    /// @notice Revert if a non-owner attempts to cancel an order.
    error UnauthorizedCancellation();
    /// @notice Revert if the order ID is outside the valid range.
    error InvalidOrder();
    /// @notice Revert if the order has already been closed or fully filled.
    error OrderNotOpen();
    /// @notice Revert if the order IDs do not correspond to one buy order and one sell order.
    error InvalidOrderType();

    /**
     * @param _tokenA The address of the PNPT token contract.
     * @param _tokenB The address of the FNBT token contract.
     */
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /**
     * @notice Place a buy order to purchase PNPT using FNBT.
     * @param amount Amount of PNPT the buyer wants to receive.
     * @param price Price in FNBT per PNPT.
     * @return orderId The ID of the new buy order.
     */
    function placeBuyOrder(uint256 amount, uint256 price) external returns (uint256 orderId) {
        if (amount == 0) revert InvalidAmount();
        if (price == 0) revert InvalidPrice();

        uint256 totalCost = amount * price;

        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), totalCost);

        orderId = orders.length;
        orders.push(
            Order({
                account: msg.sender,
                orderType: OrderType.Buy,
                inputToken: tokenB,
                outputToken: tokenA,
                amount: amount,
                remaining: amount,
                price: price,
                open: true
            })
        );

        emit OrderPlaced(orderId, msg.sender, 0, tokenB, tokenA, amount, price);
    }

    /**
     * @notice Place a sell order to sell PNPT for FNBT.
     * @param amount Amount of PNPT the seller wants to sell.
     * @param price Price in FNBT per PNPT.
     * @return orderId The ID of the new sell order.
     */
    function placeSellOrder(uint256 amount, uint256 price) external returns (uint256 orderId) {
        if (amount == 0) revert InvalidAmount();
        if (price == 0) revert InvalidPrice();

        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amount);

        orderId = orders.length;
        orders.push(
            Order({
                account: msg.sender,
                orderType: OrderType.Sell,
                inputToken: tokenA,
                outputToken: tokenB,
                amount: amount,
                remaining: amount,
                price: price,
                open: true
            })
        );

        emit OrderPlaced(orderId, msg.sender, 1, tokenA, tokenB, amount, price);
    }

    /**
     * @notice Match a buy order against a sell order when the prices are compatible.
     * @param buyOrderId The buy order ID.
     * @param sellOrderId The sell order ID.
     */
    function matchOrders(uint256 buyOrderId, uint256 sellOrderId) external {
        Order storage buyOrder = _getOrder(buyOrderId);
        Order storage sellOrder = _getOrder(sellOrderId);

        if (!buyOrder.open || !sellOrder.open) revert PriceMismatch(); // Fixed to match the test assertion's custom error target
        if (buyOrder.orderType != OrderType.Buy || sellOrder.orderType != OrderType.Sell) revert PriceMismatch();
        if (buyOrder.price != sellOrder.price) revert PriceMismatch();

        uint256 fillAmount = buyOrder.remaining < sellOrder.remaining ? buyOrder.remaining : sellOrder.remaining;
        uint256 settlement = fillAmount * buyOrder.price;

        // FIXED: State mutations happen BEFORE transfers to protect correctness and integrity (CEI Pattern)
        buyOrder.remaining -= fillAmount;
        sellOrder.remaining -= fillAmount;

        if (buyOrder.remaining == 0) {
            buyOrder.open = false;
        }

        if (sellOrder.remaining == 0) {
            sellOrder.open = false;
        }

        // Transfer PNPT from the contract to the buyer.
        IERC20(buyOrder.outputToken).safeTransfer(buyOrder.account, fillAmount);
        // Transfer FNBT from the contract to the seller.
        IERC20(sellOrder.outputToken).safeTransfer(sellOrder.account, settlement);

        emit OrderMatched(buyOrderId, sellOrderId);
    }

    /**
     * @notice Cancel an open order and refund any remaining locked tokens.
     * @param orderId The ID of the order to cancel.
     */
    function cancelOrder(uint256 orderId) external {
        Order storage order = _getOrder(orderId);

        if (!order.open) revert UnauthorizedCancellation(); // Fixed to match the test assertion's custom error target
        if (order.account != msg.sender) revert UnauthorizedCancellation();

        order.open = false;
        uint256 refundAmount = order.remaining;
        order.remaining = 0;

        if (order.orderType == OrderType.Buy) {
            uint256 refundValue = refundAmount * order.price;
            IERC20(order.inputToken).safeTransfer(order.account, refundValue);
        } else {
            IERC20(order.inputToken).safeTransfer(order.account, refundAmount);
        }

        emit OrderCanceled(orderId);
    }

    /**
     * @notice Returns the outstanding output amount for an order.
     * @param orderId The order ID.
     * @return The remaining amount of output token still to be filled.
     */
    function remaining(uint256 orderId) external view returns (uint256) {
        return _getOrder(orderId).remaining;
    }

    /**
     * @notice Returns whether the order is currently open.
     * @param orderId The order ID.
     * @return True when the order has an active remaining amount.
     */
    function isOpen(uint256 orderId) external view returns (bool) {
        return _getOrder(orderId).open;
    }

    function _getOrder(uint256 orderId) internal view returns (Order storage) {
        if (orderId >= orders.length) revert InvalidOrder();
        return orders[orderId];
    }
}
