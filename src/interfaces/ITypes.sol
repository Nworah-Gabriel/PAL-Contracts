// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title PAL Common Types
 * @notice Shared type definitions for PAL contracts
 */
library PALTypes {
    // Transaction types
    enum TransactionType { Sale, Purchase, Expense }
    
    // Project statuses
    enum ProjectStatus { Active, Completed, Cancelled, Overdue }
    
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
}