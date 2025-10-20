// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PalCore.sol";

/**
 * @title PAL Fuzz Tests
 * @notice Property-based testing for edge cases and security
 * @dev Uses fuzzing to test with random inputs and find vulnerabilities
 */
contract PALFuzzTest is Test {
    PalCore public pal;

    address teamWallet = address(0x1);

    function setUp() public {
        pal = new PalCore(teamWallet);
    }

    function testFuzz_CreateBusiness(
        address user,
        string memory name,
        string memory businessType
    ) public {
        // Bound the string lengths to reasonable sizes
        vm.assume(bytes(name).length > 0 && bytes(name).length <= 100);
        vm.assume(
            bytes(businessType).length > 0 && bytes(businessType).length <= 50
        );
        vm.assume(user != address(0));

        vm.prank(user);
        pal.createBusinessAccount(name, businessType);

        assertTrue(address(pal.businessAccounts(user)) != address(0));
    }

    function testFuzz_TransactionAmounts(uint256 amount) public {
        // Create a business first
        address user = address(0x123);
        vm.prank(user);
        pal.createBusinessAccount("Test Biz", "Retail");

        // Bound amount to prevent overflow
        amount = bound(amount, 1, 1000 ether);

        vm.prank(user);
        pal.recordTransaction(
            amount,
            "Test",
            "Test",
            IPAL.TransactionType.Sale
        );

        (uint256 sales, , , uint256 balance) = pal.getFinancialSummary(1);
        assertEq(sales, amount);
        assertEq(balance, amount);
    }

    function testFuzz_MultipleTransactions(uint8 transactionCount) public {
        // Use smaller bounds to avoid gas issues
        transactionCount = uint8(bound(transactionCount, 1, 10));

        address user = address(0x123);
        vm.prank(user);
        pal.createBusinessAccount("Test Biz", "Retail");

        uint256 totalSales = 0;
        uint256 totalExpenses = 0;

        for (uint8 i = 0; i < transactionCount; i++) {
            uint256 amount = (i + 1) * 0.1 ether; // Smaller amounts to avoid overflow
            IPAL.TransactionType txType = i % 2 == 0
                ? IPAL.TransactionType.Sale
                : IPAL.TransactionType.Expense;

            if (txType == IPAL.TransactionType.Sale) {
                totalSales += amount;
            } else {
                // Ensure we have enough balance for expenses
                if (totalSales - totalExpenses >= amount) {
                    totalExpenses += amount;
                } else {
                    // If not enough balance, make it a sale instead
                    txType = IPAL.TransactionType.Sale;
                    totalSales += amount;
                }
            }

            vm.prank(user);
            pal.recordTransaction(amount, "Category", "Description", txType);
        }

        (
            uint256 actualSales,
            uint256 actualExpenses,
            int256 profit,
            uint256 balance
        ) = pal.getFinancialSummary(1);

        assertEq(actualSales, totalSales);
        assertEq(actualExpenses, totalExpenses);
        assertEq(profit, int256(totalSales) - int256(totalExpenses));
        assertEq(balance, totalSales - totalExpenses);
    }

    function testFuzz_BusinessIsolation(address user1, address user2) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);

        // User1 creates business
        vm.prank(user1);
        pal.createBusinessAccount("Biz1", "Type1");

        // User2 creates business
        vm.prank(user2);
        pal.createBusinessAccount("Biz2", "Type2");

        // Verify isolation
        assertTrue(address(pal.businessAccounts(user1)) != address(0));
        assertTrue(address(pal.businessAccounts(user2)) != address(0));
        assertTrue(
            address(pal.businessAccounts(user1)) !=
                address(pal.businessAccounts(user2))
        );
    }
}
