// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./PalStorage.sol";
import "./PalGovernance.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title PAL: Agentic AI Business Assistant - Core Contract
 * @notice Main business logic contract for PAL AI Assistant
 * @dev Handles business operations, decision-making, and integrations
 */
contract PALCore is PALGovernance {
    using Strings for uint256;
    
    PALDataStorage public dataStorage;

    // Events
    event BusinessRegistered(address indexed owner, uint256 businessId);
    event SalesLogged(uint256 indexed businessId, uint256 amount, uint256 timestamp);
    event ExpenseLogged(uint256 indexed businessId, uint256 amount, string category, uint256 timestamp);
    event AlertTriggered(uint256 indexed businessId, string alertType, string message);
    event RecommendationMade(uint256 indexed businessId, string recommendationType, string details);

    /**
     * @dev Constructor initializes the data storage contract
     * @param _dataStorageAddress Address of the PALDataStorage contract
     */
    constructor(address _dataStorageAddress) {
        dataStorage = PALDataStorage(_dataStorageAddress);
    }

    

    /**
     * @notice Register a new business with PAL
     * @param _businessName Name of the business
     * @param _industry Industry category
     * @param _initialBalance Initial business balance
     */
    function registerBusiness(
        string memory _businessName,
        string memory _industry,
        uint256 _initialBalance
    ) external {
        uint256 businessId = dataStorage.createBusiness(
            msg.sender,
            _businessName,
            _industry,
            _initialBalance
        );
        
        emit BusinessRegistered(msg.sender, businessId);
    }

    /**
     * @notice Log a sale transaction
     * @param _businessId ID of the business
     * @param _amount Sale amount
     * @param _productId Product/service ID (optional)
     */
    function logSale(
        uint256 _businessId,
        uint256 _amount,
        string memory _productId
    ) external onlyBusinessOwner(_businessId) {
        dataStorage.recordSale(_businessId, _amount, _productId);
        
        // Check inventory and trigger alerts if needed
        _checkInventoryLevels(_businessId);
        
        emit SalesLogged(_businessId, _amount, block.timestamp);
    }

    /**
     * @notice Log an expense
     * @param _businessId ID of the business
     * @param _amount Expense amount
     * @param _category Expense category
     */
    function logExpense(
        uint256 _businessId,
        uint256 _amount,
        string memory _category
    ) external onlyBusinessOwner(_businessId) {
        dataStorage.recordExpense(_businessId, _amount, _category);
        
        // Check cash flow and trigger alerts if needed
        _checkCashFlow(_businessId);
        
        emit ExpenseLogged(_businessId, _amount, _category, block.timestamp);
    }

    function _checkInventoryLevels(uint256 _businessId) internal {
        uint256 currentInventory = dataStorage.getInventoryLevel(_businessId, "default");
        uint256 threshold = dataStorage.getInventoryThreshold(_businessId, "default");
        
        if (currentInventory < threshold) {
            string memory alertMessage = string(abi.encodePacked(
                "Low inventory alert! Current: ",
                currentInventory.toString(),
                ", Threshold: ",
                threshold.toString()
            ));
            
            dataStorage.recordAlert(_businessId, "LOW_INVENTORY", alertMessage);
            emit AlertTriggered(_businessId, "LOW_INVENTORY", alertMessage);
        }
    }

    /**
     * @dev Internal function to check cash flow status
     * @param _businessId ID of the business
     */
    function _checkCashFlow(uint256 _businessId) internal {
        // Implementation would analyze cash flow patterns
        // This is a simplified version for demonstration
        
        uint256 balance = dataStorage.getBusinessBalance(_businessId);
        uint256 avgExpenses = dataStorage.getAverageExpenses(_businessId, 30); // 30-day average
        
        if (balance < avgExpenses) {
            string memory alertMessage = string(abi.encodePacked(
                "Cash flow warning! Current balance: ",
                Strings.toString(balance),
                ", 30-day avg expenses: ",
                Strings.toString(avgExpenses)
            ));
            
            dataStorage.recordAlert(_businessId, "CASH_FLOW_WARNING", alertMessage);
            emit AlertTriggered(_businessId, "CASH_FLOW_WARNING", alertMessage);
        }
    }

    /**
     * @notice Run a "What If" scenario analysis
     * @param _businessId ID of the business
     * @param _scenarioType Type of scenario ("PRICE_INCREASE", "NEW_EXPENSE", etc.)
     * @param _parameters Parameters for the scenario
     */
    function runScenario(
        uint256 _businessId,
        string memory _scenarioType,
        uint256[] memory _parameters
    ) external onlyBusinessOwner(_businessId) returns (string memory) {
        // This would be more complex in a real implementation
        if (keccak256(bytes(_scenarioType)) == keccak256(bytes("PRICE_INCREASE"))) {
            require(_parameters.length >= 1, "Missing percentage parameter");
            uint256 currentRevenue = dataStorage.getRevenue(_businessId, 30); // 30-day revenue
            uint256 newRevenue = currentRevenue * (100 + _parameters[0]) / 100;
            
            string memory result = string(abi.encodePacked(
                "Projected revenue change: ",
                Strings.toString(_parameters[0]),
                "% increase would result in ",
                Strings.toString(newRevenue),
                " vs current ",
                Strings.toString(currentRevenue)
            ));
            
            emit RecommendationMade(_businessId, "PRICE_ADJUSTMENT", result);
            return result;
        }
        
        revert("Unsupported scenario type");
    }

    // Additional business logic functions would be added here...
    
    modifier onlyBusinessOwner(uint256 _businessId) {
        require(dataStorage.isBusinessOwner(_businessId, msg.sender), "Not business owner");
        _;
    }
}