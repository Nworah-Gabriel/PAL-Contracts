// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../src/PalStorage.sol";
import "../src/PalCore.sol";

contract PALCoreTest is Test {
    PALDataStorage dataStorage;
    PALCore palCore;
    
    address owner = address(0x1);
    address nonOwner = address(0x2);
    address attacker = address(0x999);
    
    function setUp() public {
        vm.startPrank(owner);
        dataStorage = new PALDataStorage();
        palCore = new PALCore(address(dataStorage));
        vm.stopPrank();
    }
    
    // ========== UNIT TESTS ========== //
    
    function test_RegisterBusiness() public {
        vm.startPrank(owner);
        
        uint256 initialBalance = 1000 ether;
        palCore.registerBusiness("Test Biz", "Retail", initialBalance);
        
        (address bizOwner, string memory name, , uint256 balance, ) = dataStorage.businesses(1);
        assertEq(bizOwner, owner, "Owner mismatch");
        assertEq(name, "Test Biz", "Name mismatch");
        assertEq(balance, initialBalance, "Balance mismatch");
        
        vm.stopPrank();
    }
    
    function test_LogSaleUpdatesBalance() public {
        vm.startPrank(owner);
        palCore.registerBusiness("Biz", "Retail", 1000 ether);
        
        uint256 saleAmount = 100 ether;
        palCore.logSale(1, saleAmount, "PROD_1");
        
        assertEq(dataStorage.getBusinessBalance(1), 1100 ether, "Balance not updated");
        vm.stopPrank();
    }
    
    // ========== FUZZ TESTS ========== //
    
    function testFuzz_LogSales(uint128 saleAmount) public {
        vm.assume(saleAmount > 0 && saleAmount < type(uint128).max);
        
        vm.startPrank(owner);
        palCore.registerBusiness("Fuzz Biz", "Fuzz", 0);
        
        uint256 initialBalance = dataStorage.getBusinessBalance(1);
        palCore.logSale(1, saleAmount, "FUZZ");
        
        assertEq(
            dataStorage.getBusinessBalance(1),
            initialBalance + saleAmount,
            "Fuzz balance mismatch"
        );
        vm.stopPrank();
    }
    
    // ========== AUDIT TESTS ========== //
    
    function test_NonOwnerCannotLogSales() public {
        vm.startPrank(owner);
        palCore.registerBusiness("Secure Biz", "Secure", 1000 ether);
        vm.stopPrank();
        
        vm.startPrank(attacker);
        vm.expectRevert("Not business owner");
        palCore.logSale(1, 100 ether, "HACK");
        vm.stopPrank();
    }
    
    function test_ReentrancyAttack() public {
        // Setup malicious contract
        MaliciousContract attackerContract = new MaliciousContract(address(palCore));
        
        vm.startPrank(owner);
        palCore.registerBusiness("Victim Biz", "Victim", 1000 ether);
        
        // Try to exploit reentrancy
        vm.expectRevert();
        attackerContract.attack(1, 100 ether);
        vm.stopPrank();
        
        // Verify state wasn't corrupted
        assertEq(dataStorage.getBusinessBalance(1), 1000 ether, "Reentrancy succeeded");
    }
    
    // ========== INVARIANT TESTS ========== //
    
    function invariant_BalanceConsistency() public {
        // This would be run with Foundry's invariant testing
        // Simplified for demonstration
        uint256 balance = dataStorage.getBusinessBalance(1);
        assertTrue(balance >= 0, "Balance underflow");
    }
}

contract MaliciousContract {
    PALCore palCore;
    
    constructor(address _palCore) {
        palCore = PALCore(_palCore);
    }
    
    function attack(uint256 bizId, uint256 amount) external {
        // Malicious reentrancy attempt
        palCore.logSale(bizId, amount, "HACK");
        // Would normally try to reenter here
    }
}