// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IPAL} from "./interfaces/IPal.sol";
import {BusinessAccount} from "./BusinessAccount.sol";
import {TransactionManager} from "./TransactionManager.sol";
import {ProjectTracker} from "./ProjectTracker.sol";

/**
 * @title PAL Main Contract
 * @notice Core contract for PAL business management system on Base
 * @dev Manages business accounts, transactions, and project tracking
 */
contract PalCore is IPAL {
    // State variables
    address public immutable teamWallet;
    uint256 public businessCounter;

    // Mappings
    mapping(address => BusinessAccount) public businessAccounts;
    mapping(uint256 => address) public businessIdToOwner;
    mapping(address => uint256) public ownerToBusinessId;

    // Contract references
    TransactionManager public transactionManager;
    ProjectTracker public projectTracker;

    /**
     * @dev Constructor sets the team wallet and deploys manager contracts
     * @param _teamWallet Address of the team/admin wallet
     */
    constructor(address _teamWallet) {
        require(_teamWallet != address(0), "PAL: team wallet cannot be zero");
        teamWallet = _teamWallet;

        // Deploy manager contracts
        transactionManager = new TransactionManager();
        projectTracker = new ProjectTracker();

        businessCounter = 1;
    }

    /**
     * @notice Creates a new business account for the caller
     * @dev Each wallet can only have one business account
     * @param _name Business name
     * @param _businessType Type of business
     */
    function createBusinessAccount(
        string calldata _name,
        string calldata _businessType
    ) external override {
        require(bytes(_name).length > 0, "PAL: business name required");
        require(bytes(_businessType).length > 0, "PAL: business type required");
        require(
            address(businessAccounts[msg.sender]) == address(0),
            "PAL: business already exists"
        );
        require(
            ownerToBusinessId[msg.sender] == 0,
            "PAL: business already exists"
        );

        // Create new business account
        BusinessAccount newBusiness = new BusinessAccount(
            businessCounter,
            msg.sender,
            _name,
            _businessType
        );

        // Update mappings
        businessAccounts[msg.sender] = newBusiness;
        businessIdToOwner[businessCounter] = msg.sender;
        ownerToBusinessId[msg.sender] = businessCounter;

        emit BusinessAccountCreated(
            businessCounter,
            msg.sender,
            _name,
            _businessType,
            block.timestamp
        );

        businessCounter++;
    }

    /**
     * @notice Records a business transaction
     * @dev Can only be called by business owner
     * @param _amount Transaction amount in wei
     * @param _category Transaction category
     * @param _description Transaction description
     * @param _txType Type of transaction (Sale/Purchase/Expense)
     */
    function recordTransaction(
        uint256 _amount,
        string calldata _category,
        string calldata _description,
        TransactionType _txType
    ) external override {
        BusinessAccount business = businessAccounts[msg.sender];
        require(address(business) != address(0), "PAL: no business account");
        require(_amount > 0, "PAL: amount must be positive");
        require(bytes(_category).length > 0, "PAL: category required");

        transactionManager.recordTransaction(
            address(business),
            _amount,
            _category,
            _description,
            _txType
        );

        emit TransactionRecorded(
            ownerToBusinessId[msg.sender],
            _amount,
            _category,
            _description,
            _txType,
            block.timestamp
        );
    }

    /**
     * @notice Adds a new project/client
     * @dev Can only be called by business owner
     * @param _clientName Name of the client
     * @param _projectName Name of the project
     * @param _amount Project amount
     * @param _deadline Project deadline timestamp
     */
    function addProject(
        string calldata _clientName,
        string calldata _projectName,
        uint256 _amount,
        uint256 _deadline
    ) external override {
        BusinessAccount business = businessAccounts[msg.sender];
        require(address(business) != address(0), "PAL: no business account");
        require(bytes(_clientName).length > 0, "PAL: client name required");
        require(bytes(_projectName).length > 0, "PAL: project name required");
        require(_amount > 0, "PAL: amount must be positive");
        require(_deadline > block.timestamp, "PAL: deadline must be in future");

        projectTracker.addProject(
            address(business),
            _clientName,
            _projectName,
            _amount,
            _deadline
        );

        emit ProjectAdded(
            ownerToBusinessId[msg.sender],
            _clientName,
            _projectName,
            _amount,
            _deadline,
            ProjectStatus.Active
        );
    }

    /**
     * @notice Updates project status
     * @dev Can only be called by business owner
     * @param _projectId Project ID to update
     * @param _newStatus New project status
     */
    function updateProjectStatus(
        uint256 _projectId,
        ProjectStatus _newStatus
    ) external override {
        BusinessAccount business = businessAccounts[msg.sender];
        require(address(business) != address(0), "PAL: no business account");

        projectTracker.updateProjectStatus(
            address(business),
            _projectId,
            _newStatus
        );

        emit ProjectStatusUpdated(
            ownerToBusinessId[msg.sender],
            _projectId,
            _newStatus,
            block.timestamp
        );
    }

    /**
     * @notice Gets business financial summary
     * @param _businessId Business ID to query
     * @return totalSales Total sales amount
     * @return totalExpenses Total expenses amount
     * @return netProfit Net profit amount
     * @return currentBalance Current balance
     */
    function getFinancialSummary(
        uint256 _businessId
    )
        external
        view
        override
        returns (
            uint256 totalSales,
            uint256 totalExpenses,
            int256 netProfit,
            uint256 currentBalance
        )
    {
        address businessOwner = businessIdToOwner[_businessId];
        require(businessOwner != address(0), "PAL: invalid business ID");

        BusinessAccount business = businessAccounts[businessOwner];
        return transactionManager.getFinancialSummary(address(business));
    }

    /**
     * @notice Gets business account info
     * @param _businessId Business ID to query
     * @return Business account information
     */
    function getBusinessInfo(
        uint256 _businessId
    ) external view override returns (BusinessAccountInfo memory) {
        address businessOwner = businessIdToOwner[_businessId];
        require(businessOwner != address(0), "PAL: invalid business ID");

        BusinessAccount business = businessAccounts[businessOwner];
        return business.getBusinessInfo();
    }

    /**
     * @notice Gets all projects for a business
     * @param _businessId Business ID to query
     * @return Array of projects
     */
    function getProjects(
        uint256 _businessId
    ) external view override returns (Project[] memory) {
        address businessOwner = businessIdToOwner[_businessId];
        require(businessOwner != address(0), "PAL: invalid business ID");

        BusinessAccount business = businessAccounts[businessOwner];
        return projectTracker.getProjects(address(business));
    }

    /**
     * @notice Gets overdue projects for a business
     * @param _businessId Business ID to query
     * @return Array of overdue projects
     */
    function getOverdueProjects(
        uint256 _businessId
    ) external view override returns (Project[] memory) {
        address businessOwner = businessIdToOwner[_businessId];
        require(businessOwner != address(0), "PAL: invalid business ID");

        BusinessAccount business = businessAccounts[businessOwner];
        return projectTracker.getOverdueProjects(address(business));
    }

    // Admin functions
    /**
     * @notice Emergency function to pause contract (team only)
     * @dev Only callable by team wallet
     */
    function emergencyPause() external override {
        require(msg.sender == teamWallet, "PAL: team only");
        // Implementation for pausing functionality
        emit EmergencyPaused(block.timestamp);
    }
}
