// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// IPAL.sol
interface IPAL {
    // Transaction types
    enum TransactionType {
        Sale,
        Purchase,
        Expense
    }

    // Project statuses
    enum ProjectStatus {
        Active,
        Completed,
        Cancelled,
        Overdue
    }

    // Business account information
    struct BusinessAccountInfo {
        uint256 businessId;
        address owner;
        string businessName;
        string businessType;
        uint256 createdAt;
    }

    // Transaction structure
    struct Transaction {
        uint256 id;
        uint256 amount;
        string category;
        string description;
        TransactionType txType;
        uint256 timestamp;
    }

    // Project structure
    struct Project {
        uint256 id;
        string clientName;
        string projectName;
        uint256 amount;
        uint256 deadline;
        ProjectStatus status;
        uint256 createdAt;
    }

    // Events
    event BusinessAccountCreated(
        uint256 indexed businessId,
        address indexed owner,
        string businessName,
        string businessType,
        uint256 timestamp
    );

    event TransactionRecorded(
        uint256 indexed businessId,
        uint256 amount,
        string category,
        string description,
        TransactionType txType,
        uint256 timestamp
    );

    event ProjectAdded(
        uint256 indexed businessId,
        string clientName,
        string projectName,
        uint256 amount,
        uint256 deadline,
        ProjectStatus status
    );

    event ProjectStatusUpdated(
        uint256 indexed businessId,
        uint256 indexed projectId,
        ProjectStatus newStatus,
        uint256 timestamp
    );

    event EmergencyPaused(uint256 timestamp);
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

    function createBusinessAccount(
        string calldata _name,
        string calldata _businessType
    ) external;

    function recordTransaction(
        uint256 _amount,
        string calldata _category,
        string calldata _description,
        TransactionType _txType
    ) external;

    function addProject(
        string calldata _clientName,
        string calldata _projectName,
        uint256 _amount,
        uint256 _deadline
    ) external;

    function updateProjectStatus(
        uint256 _projectId,
        ProjectStatus _newStatus
    ) external;

    function getFinancialSummary(
        uint256 _businessId
    )
        external
        view
        returns (
            uint256 totalSales,
            uint256 totalExpenses,
            int256 netProfit,
            uint256 currentBalance
        );

    function getBusinessInfo(
        uint256 _businessId
    ) external view returns (BusinessAccountInfo memory);

    function getProjects(
        uint256 _businessId
    ) external view returns (Project[] memory);

    function getOverdueProjects(
        uint256 _businessId
    ) external view returns (Project[] memory);

    function emergencyPause() external;
}
