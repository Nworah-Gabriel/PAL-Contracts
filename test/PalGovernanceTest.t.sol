// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PalGovernance.sol";

contract PALGovernanceTest is Test {
    PALGovernance governance;
    
    address owner = address(0x1);
    address nonOwner = address(0x2);
    
    function setUp() public {
        vm.startPrank(owner);
        governance = new PALGovernance();
        governance.initialize();
        vm.stopPrank();
    }
    
    // ========== UNIT TESTS ========== //
    
    function test_UpgradeFlow() public {
        address newImplementation = address(0x999);
        
        vm.startPrank(owner);
        governance.proposeUpgrade(newImplementation);
        
        // Fast forward time
        vm.warp(block.timestamp + governance.UPGRADE_DELAY() + 1);
        
        governance.completeUpgrade();
        assertEq(governance.implementation(), newImplementation, "Upgrade failed");
        vm.stopPrank();
    }
    
    // ========== AUDIT TESTS ========== //
    
    function test_OnlyOwnerCanUpgrade() public {
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        governance.proposeUpgrade(address(0x999));
        vm.stopPrank();
    }
    
    function test_UpgradeDelayEnforced() public {
        vm.startPrank(owner);
        governance.proposeUpgrade(address(0x999));
        
        // Try to upgrade too soon
        vm.expectRevert();
        governance.completeUpgrade();
        
        vm.stopPrank();
    }
}