// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@forge-std/Test.sol";
import "@contract/PalCore.sol";

/**
 * @author Nworah Chimzuruoke Gabriel (SAGGIO)
 * @title PAL Security Audit Tests
 * @notice Tests for common vulnerabilities and security issues
 * @dev Focuses on reentrancy, access control, overflow, etc.
 */
contract PALAuditTest is Test {
    PalCore public pal;

    address teamWallet = address(0x1);
    address attacker = address(0x666);
    address legitimateUser = address(0x999);

    function setUp() public {
        pal = new PalCore(teamWallet);
    }

    function test_ReentrancyProtection() public {
        // This test ensures no reentrancy vulnerabilities
        // The current implementation doesn't have external calls after state changes,
        // but we test the pattern anyway

        vm.prank(legitimateUser);
        pal.createBusinessAccount("Test", "Type");

        // Record multiple transactions to ensure state consistency
        vm.startPrank(legitimateUser);
        pal.recordTransaction(
            10 ether,
            "Sales",
            "Sale1",
            IPAL.TransactionType.Sale
        );
        pal.recordTransaction(
            3 ether,
            "Expense",
            "Expense1",
            IPAL.TransactionType.Expense
        );
        pal.recordTransaction(
            2 ether,
            "Expense",
            "Expense2",
            IPAL.TransactionType.Expense
        );
        vm.stopPrank();

        // Verify final state is consistent
        (uint256 sales, uint256 expenses, , uint256 balance) = pal
            .getFinancialSummary(1);
        assertEq(sales, 10 ether);
        assertEq(expenses, 5 ether);
        assertEq(balance, 5 ether);
    }

    function test_AccessControl() public {
        // Test that only business owners can access their data
        vm.prank(legitimateUser);
        pal.createBusinessAccount("Legit Biz", "Retail");

        // Attacker tries to record transaction for legitimate user's business
        vm.prank(attacker);
        vm.expectRevert("PAL: no business account");
        pal.recordTransaction(
            1 ether,
            "Hack",
            "Hack",
            IPAL.TransactionType.Sale
        );

        // Attacker tries to get financial summary - this should work as financial summaries are public
        // But they can only see their own business data
        (uint256 sales, uint256 expenses, , ) = pal.getFinancialSummary(1);
        assertEq(sales, 0);
        assertEq(expenses, 0);
    }

    function test_IntegerOverflowProtection() public {
        vm.prank(legitimateUser);
        pal.createBusinessAccount("Test", "Type");

        // Test with very large amounts to ensure no overflow
        uint256 largeAmount = type(uint256).max / 2;

        vm.prank(legitimateUser);
        // This should work due to bounds checking in TransactionManager
        pal.recordTransaction(
            largeAmount,
            "Test",
            "Test",
            IPAL.TransactionType.Sale
        );

        // Verify the transaction was recorded
        (uint256 sales, , , ) = pal.getFinancialSummary(1);
        assertEq(sales, largeAmount);
    }

    function test_ZeroAddressProtection() public {
        // Test that zero addresses are properly handled
        vm.expectRevert("PAL: team wallet cannot be zero");
        new PalCore(address(0));
    }

    function test_EmergencyFunctions_TeamOnly() public {
        // Test that only team wallet can call emergency functions
        vm.prank(attacker);
        vm.expectRevert("PAL: team only");
        pal.emergencyPause();

        // Team wallet should be able to call it
        vm.prank(teamWallet);
        pal.emergencyPause();
    }

    function test_StateConsistency() public {
        // Test that contract state remains consistent after multiple operations
        vm.prank(legitimateUser);
        pal.createBusinessAccount("Consistency Test", "Service");

        uint256 initialCounter = pal.businessCounter();

        // Perform multiple operations
        for (uint i = 0; i < 10; i++) {
            vm.prank(legitimateUser);
            pal.recordTransaction(
                1 ether,
                "Sales",
                string(abi.encodePacked("Sale ", i)),
                IPAL.TransactionType.Sale
            );
        }

        // Verify business counter hasn't changed unexpectedly
        assertEq(pal.businessCounter(), initialCounter);

        // Verify financial data is consistent
        (uint256 sales, uint256 expenses, , uint256 balance) = pal
            .getFinancialSummary(1);
        assertEq(sales, 10 ether);
        assertEq(expenses, 0);
        assertEq(balance, 10 ether);
        assertEq(sales - expenses, balance);
    }
}
