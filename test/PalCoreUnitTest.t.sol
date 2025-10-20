// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PalCore.sol";
import "../src/BusinessAccount.sol";
import "../src/TransactionManager.sol";

/**
 * @title PAL Unit Tests
 * @notice Comprehensive unit tests for PAL smart contracts
 * @dev Tests individual contract functionality in isolation
 */
contract PALUnitTest is Test {
    PalCore public pal;
    TransactionManager public txManager;

    address teamWallet = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function setUp() public {
        pal = new PalCore(teamWallet);
        txManager = pal.transactionManager();
    }

    function test_Constructor() public view {
        assertEq(pal.teamWallet(), teamWallet);
        assertEq(pal.businessCounter(), 1);
        assertTrue(address(pal.transactionManager()) != address(0));
        assertTrue(address(pal.projectTracker()) != address(0));
    }

    function test_CreateBusinessAccount() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        assertEq(pal.ownerToBusinessId(user1), 1);
        assertEq(pal.businessIdToOwner(1), user1);
        assertTrue(address(pal.businessAccounts(user1)) != address(0));
    }

    function test_CreateBusinessAccount_Revert_When_EmptyName() public {
        vm.prank(user1);
        vm.expectRevert("PAL: business name required");
        pal.createBusinessAccount("", "Retail");
    }

    function test_CreateBusinessAccount_Revert_When_AlreadyExists() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        // Try to create another business with same user - should revert
        vm.expectRevert("PAL: business already exists");
        pal.createBusinessAccount("Another Biz", "Service");
    }

    function test_RecordTransaction() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        vm.prank(user1);
        pal.recordTransaction(
            1 ether,
            "Product Sale",
            "Test sale",
            IPAL.TransactionType.Sale
        );

        (uint256 sales, uint256 expenses, int256 profit, uint256 balance) = pal
            .getFinancialSummary(1);
        assertEq(sales, 1 ether);
        assertEq(expenses, 0);
        assertEq(profit, int256(1 ether));
        assertEq(balance, 1 ether);
    }

    function test_RecordTransaction_Revert_When_NoBusiness() public {
        vm.prank(user1);
        vm.expectRevert("PAL: no business account");
        pal.recordTransaction(
            1 ether,
            "Test",
            "Test",
            IPAL.TransactionType.Sale
        );
    }

    function test_RecordTransaction_Revert_When_ZeroAmount() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        vm.prank(user1);
        vm.expectRevert("PAL: amount must be positive");
        pal.recordTransaction(0, "Test", "Test", IPAL.TransactionType.Sale);
    }

    function test_Fuzz_CreateMultipleBusinesses(uint8 count) public {
        count = uint8(bound(count, 1, 50)); // Reasonable bounds for fuzzing

        for (uint256 i = 0; i < count; i++) {
            address user = address(uint160(i + 100)); // Generate unique addresses
            vm.prank(user);
            pal.createBusinessAccount("Business", "Type");
        }

        assertEq(pal.businessCounter(), count + 1); // +1 for initial counter
    }

    function test_Fuzz_RecordVariousTransactions(
        uint256 amount,
        uint8 txType
    ) public {
        amount = bound(amount, 1, 1000 ether);
        txType = txType % 3; // Ensure valid transaction type

        address user = address(0x123);
        vm.prank(user);
        pal.createBusinessAccount("Test Biz", "Retail");

        IPAL.TransactionType transactionType = IPAL.TransactionType(txType);

        if (transactionType == IPAL.TransactionType.Sale) {
            vm.prank(user);
            pal.recordTransaction(amount, "Sale", "Test", transactionType);

            (uint256 sales, , , uint256 balance) = pal.getFinancialSummary(1);
            assertEq(sales, amount);
            assertEq(balance, amount);
        } else {
            // First record a sale to have balance
            vm.prank(user);
            pal.recordTransaction(
                amount * 2,
                "Sale",
                "Test",
                IPAL.TransactionType.Sale
            );

            vm.prank(user);
            pal.recordTransaction(amount, "Expense", "Test", transactionType);

            (uint256 sales, uint256 expenses, , uint256 balance) = pal
                .getFinancialSummary(1);
            assertEq(sales, amount * 2);
            assertEq(expenses, amount);
            assertEq(balance, amount);
        }
    }
}
