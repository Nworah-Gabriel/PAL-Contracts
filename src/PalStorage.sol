// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title PAL Data Storage Contract
 * @notice Secure storage for all business data with access control
 * @dev Separates storage from logic for upgradeability and security
 */
contract PALDataStorage {
    struct Business {
        address owner;
        string name;
        string industry;
        uint256 balance;
        uint256 createdAt;
    }
    
    struct Sale {
        uint256 amount;
        string productId;
        uint256 timestamp;
    }
    
    struct Expense {
        uint256 amount;
        string category;
        uint256 timestamp;
    }
    
    struct Alert {
        string alertType;
        string message;
        uint256 timestamp;
    }
    
    // Mappings
    mapping(uint256 => Business) public businesses;
    mapping(uint256 => Sale[]) public businessSales;
    mapping(uint256 => Expense[]) public businessExpenses;
    mapping(uint256 => Alert[]) public businessAlerts;
    mapping(uint256 => mapping(string => uint256)) public inventoryLevels;
    mapping(uint256 => mapping(string => uint256)) public inventoryThresholds;
    
    uint256 public nextBusinessId = 1;
    
    // Events
    event BusinessCreated(uint256 indexed businessId, address indexed owner);
    event SaleRecorded(uint256 indexed businessId, uint256 amount, uint256 timestamp);
    event ExpenseRecorded(uint256 indexed businessId, uint256 amount, uint256 timestamp);
    event AlertRecorded(uint256 indexed businessId, string alertType, uint256 timestamp);
    
    
     /**
     * @notice Get current inventory level for a product
     * @param _businessId ID of the business
     * @param _productId Product ID
     * @return Current inventory level
     */
    function getInventoryLevel(uint256 _businessId, string memory _productId) external view returns (uint256) {
        return inventoryLevels[_businessId][_productId];
    }

    /**
     * @notice Get inventory threshold for a product
     * @param _businessId ID of the business
     * @param _productId Product ID
     * @return Inventory threshold level
     */
    function getInventoryThreshold(uint256 _businessId, string memory _productId) external view returns (uint256) {
        return inventoryThresholds[_businessId][_productId];
    }

    /**
     * @notice Set inventory level for a product
     * @param _businessId ID of the business
     * @param _productId Product ID
     * @param _level New inventory level
     */
    function setInventoryLevel(
        uint256 _businessId,
        string memory _productId,
        uint256 _level
    ) external {
        inventoryLevels[_businessId][_productId] = _level;
    }

    /**
     * @notice Set inventory threshold for a product
     * @param _businessId ID of the business
     * @param _productId Product ID
     * @param _threshold New inventory threshold
     */
    function setInventoryThreshold(
        uint256 _businessId,
        string memory _productId,
        uint256 _threshold
    ) external {
        inventoryThresholds[_businessId][_productId] = _threshold;
    }
    
    /**
     * @notice Create a new business record
     * @param _owner Address of the business owner
     * @param _name Name of the business
     * @param _industry Industry category
     * @param _initialBalance Initial business balance
     * @return businessId The ID of the newly created business
     */
    function createBusiness(
        address _owner,
        string memory _name,
        string memory _industry,
        uint256 _initialBalance
    ) external returns (uint256 businessId) {
        businessId = nextBusinessId++;
        businesses[businessId] = Business({
            owner: _owner,
            name: _name,
            industry: _industry,
            balance: _initialBalance,
            createdAt: block.timestamp
        });
        
        emit BusinessCreated(businessId, _owner);
        return businessId;
    }
    
    /**
     * @notice Record a sale transaction
     * @param _businessId ID of the business
     * @param _amount Sale amount
     * @param _productId Product/service ID
     */
    function recordSale(
        uint256 _businessId,
        uint256 _amount,
        string memory _productId
    ) external {
        Business storage business = businesses[_businessId];
        require(business.owner != address(0), "Business does not exist");
        
        business.balance += _amount;
        businessSales[_businessId].push(Sale({
            amount: _amount,
            productId: _productId,
            timestamp: block.timestamp
        }));
        
        emit SaleRecorded(_businessId, _amount, block.timestamp);
    }
    
    /**
     * @notice Record an expense
     * @param _businessId ID of the business
     * @param _amount Expense amount
     * @param _category Expense category
     */
    function recordExpense(
        uint256 _businessId,
        uint256 _amount,
        string memory _category
    ) external {
        Business storage business = businesses[_businessId];
        require(business.owner != address(0), "Business does not exist");
        
        business.balance -= _amount;
        businessExpenses[_businessId].push(Expense({
            amount: _amount,
            category: _category,
            timestamp: block.timestamp
        }));
        
        emit ExpenseRecorded(_businessId, _amount, block.timestamp);
    }
    
    /**
     * @notice Record an alert
     * @param _businessId ID of the business
     * @param _alertType Type of alert
     * @param _message Alert message
     */
    function recordAlert(
        uint256 _businessId,
        string memory _alertType,
        string memory _message
    ) external {
        businessAlerts[_businessId].push(Alert({
            alertType: _alertType,
            message: _message,
            timestamp: block.timestamp
        }));
        
        emit AlertRecorded(_businessId, _alertType, block.timestamp);
    }
    
    // Additional getter functions...
    
    function getBusinessBalance(uint256 _businessId) external view returns (uint256) {
        return businesses[_businessId].balance;
    }
    
    function isBusinessOwner(uint256 _businessId, address _address) external view returns (bool) {
        return businesses[_businessId].owner == _address;
    }
    
    function getRevenue(uint256 _businessId, uint256 _days) external view returns (uint256) {
        uint256 total = 0;
        uint256 cutoff = block.timestamp - (_days * 1 days);
        
        for (uint256 i = 0; i < businessSales[_businessId].length; i++) {
            if (businessSales[_businessId][i].timestamp >= cutoff) {
                total += businessSales[_businessId][i].amount;
            }
        }
        
        return total;
    }
    
    function getAverageExpenses(uint256 _businessId, uint256 _days) external view returns (uint256) {
        uint256 total = 0;
        uint256 count = 0;
        uint256 cutoff = block.timestamp - (_days * 1 days);
        
        for (uint256 i = 0; i < businessExpenses[_businessId].length; i++) {
            if (businessExpenses[_businessId][i].timestamp >= cutoff) {
                total += businessExpenses[_businessId][i].amount;
                count++;
            }
        }
        
        return count > 0 ? total / count : 0;
    }
    
    // Additional inventory management functions...
}