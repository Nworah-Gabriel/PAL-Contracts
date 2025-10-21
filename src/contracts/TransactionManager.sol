// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ITransactionManager} from "@interface/ITransactionManager.sol";
import {IPAL} from "@interface/IPal.sol";

/**
 * @author Nworah Chimzuruoke Gabriel (SAGGIO)
 * @title Transaction Manager Contract
 * @notice Handles all business transaction recording and financial calculations
 * @dev Manages sales, purchases, expenses and calculates financial metrics
 */
contract TransactionManager is ITransactionManager {
    // Constants
    uint256 public constant MIN_AMOUNT = 1 wei;
    uint256 public constant MAX_AMOUNT = type(uint256).max / 2; // Prevent overflow

    // Storage
    mapping(address => IPAL.Transaction[]) public businessTransactions;
    mapping(address => uint256) public businessBalances;
    mapping(address => uint256) public totalSales;
    mapping(address => uint256) public totalExpenses;

    // Alert thresholds (can be made configurable per business later)
    uint256 public constant LOW_BALANCE_THRESHOLD = 0.1 ether;
    uint256 public constant OVERSPENDING_THRESHOLD = 10 ether;

    /**
     * @notice Records a business transaction
     * @dev Internal function called by main PAL contract
     * @param _business Address of the business account
     * @param _amount Transaction amount
     * @param _category Transaction category
     * @param _description Transaction description
     * @param _txType Type of transaction
     */
    function recordTransaction(
        address _business,
        uint256 _amount,
        string calldata _category,
        string calldata _description,
        IPAL.TransactionType _txType
    ) external override {
        require(
            _business != address(0),
            "TransactionManager: business cannot be zero"
        );
        require(
            _amount >= MIN_AMOUNT && _amount <= MAX_AMOUNT,
            "TransactionManager: invalid amount"
        );
        require(
            bytes(_category).length > 0,
            "TransactionManager: category required"
        );

        // Prevent overflow in balance calculations
        if (_txType == IPAL.TransactionType.Sale) {
            require(
                businessBalances[_business] + _amount >=
                    businessBalances[_business],
                "TransactionManager: balance overflow"
            );
        } else {
            require(
                businessBalances[_business] >= _amount,
                "TransactionManager: insufficient balance"
            );
        }

        IPAL.Transaction memory newTransaction = IPAL.Transaction({
            id: businessTransactions[_business].length,
            amount: _amount,
            category: _category,
            description: _description,
            txType: _txType,
            timestamp: block.timestamp
        });

        businessTransactions[_business].push(newTransaction);

        // Update financial metrics
        if (_txType == IPAL.TransactionType.Sale) {
            totalSales[_business] += _amount;
            businessBalances[_business] += _amount;
        } else {
            totalExpenses[_business] += _amount;
            require(
                businessBalances[_business] >= _amount,
                "TransactionManager: insufficient balance"
            );
            businessBalances[_business] -= _amount;
        }

        // Check for alerts
        _checkAlerts(_business, _amount, _txType);
    }

    /**
     * @notice Gets financial summary for a business
     * @param _business Business account address
     * @return totalSales Total sales amount
     * @return totalExpenses Total expenses amount
     * @return netProfit Net profit (sales - expenses)
     * @return currentBalance Current balance
     */
    function getFinancialSummary(
        address _business
    ) external view override returns (uint256, uint256, int256, uint256) {
        uint256 sales = totalSales[_business];
        uint256 expenses = totalExpenses[_business];
        int256 profit = int256(sales) - int256(expenses);
        uint256 balance = businessBalances[_business];

        return (sales, expenses, profit, balance);
    }

    /**
     * @notice Gets transaction history for a business
     * @param _business Business account address
     * @param _limit Number of transactions to return
     * @return Array of transactions
     */
    function getTransactionHistory(
        address _business,
        uint256 _limit
    ) external view override returns (IPAL.Transaction[] memory) {
        uint256 totalTransactions = businessTransactions[_business].length;
        uint256 resultSize = _limit < totalTransactions
            ? _limit
            : totalTransactions;

        IPAL.Transaction[] memory result = new IPAL.Transaction[](resultSize);
        for (uint256 i = 0; i < resultSize; i++) {
            result[i] = businessTransactions[_business][
                totalTransactions - 1 - i
            ];
        }

        return result;
    }

    /**
     * @dev Internal function to check for alert conditions
     * @param _business Business address
     * @param _amount Transaction amount
     * @param _txType Transaction type
     */
    function _checkAlerts(
        address _business,
        uint256 _amount,
        IPAL.TransactionType _txType
    ) internal {
        uint256 balance = businessBalances[_business];

        // Low balance alert
        if (balance < LOW_BALANCE_THRESHOLD) {
            emit LowBalanceAlert(_business, balance, block.timestamp);
        }

        // Overspending alert
        if (
            _txType != IPAL.TransactionType.Sale &&
            _amount > OVERSPENDING_THRESHOLD
        ) {
            emit OverspendingAlert(_business, _amount, block.timestamp);
        }
    }
}
