// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IPAL} from "./IPal.sol";

interface ITransactionManager {
    event LowBalanceAlert(
        address indexed business,
        uint256 balance,
        uint256 timestamp
    );
    event OverspendingAlert(
        address indexed business,
        uint256 amount,
        uint256 timestamp
    );

    function recordTransaction(
        address _business,
        uint256 _amount,
        string calldata _category,
        string calldata _description,
        IPAL.TransactionType _txType
    ) external;

    function getFinancialSummary(
        address _business
    )
        external
        view
        returns (
            uint256 totalSales,
            uint256 totalExpenses,
            int256 netProfit,
            uint256 currentBalance
        );

    function getTransactionHistory(
        address _business,
        uint256 _limit
    ) external view returns (IPAL.Transaction[] memory);
}
