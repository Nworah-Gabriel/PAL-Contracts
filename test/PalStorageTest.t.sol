// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PalStorage.sol";

contract PALDataStorageTest is Test {
    PALDataStorage dataStorage;
    
    address owner = address(0x1);
    
    function setUp() public {
        dataStorage = new PALDataStorage();
    }
    
    // ========== UNIT TESTS ========== //
    
    function test_CreateBusiness() public {
        uint256 initialBalance = 500 ether;
        uint256 bizId = dataStorage.createBusiness(owner, "Test", "Retail", initialBalance);
        
        assertEq(bizId, 1, "First business should have ID 1");
        // assertEq(dataStorage.businesses(bizId).owner, owner, "Owner mismatch");
    }
    
    // ========== AUDIT TESTS ========== //
    
    // function test_DataIntegrity() public {
    //     // Create business
    //     dataStorage.createBusiness(owner, "Integrity", "Test", 100 ether);
        
    //     // Log sales
    //     uint256 saleAmount = 10 ether;
    //     dataStorage.recordSale(1, saleAmount, "TEST");
        
    //     // Verify data wasn't corrupted
    //     PALDataStorage.Sale[] memory sales = dataStorage.businessSales(1);
    //     assertEq(sales[0].amount, saleAmount, "Sale corruption");
    // }
    
    function test_OverflowProtection() public {
        dataStorage.createBusiness(owner, "Overflow", "Test", type(uint256).max);
        
        // Try to overflow balance
        vm.expectRevert();
        dataStorage.recordSale(1, 1, "OVERFLOW");
    }
}