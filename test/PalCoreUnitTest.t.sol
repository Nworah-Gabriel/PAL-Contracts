// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@forge-std/Test.sol";
import "@contract/PalCore.sol";
import "@contract/BusinessAccount.sol";
import "@contract/TransactionManager.sol";

/**
 * @author Nworah Chimzuruoke Gabriel (SAGGIO)
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
        vm.prank(user1); // ADDED THIS LINE - ensure same user
        vm.expectRevert("PAL: business already exists");
        pal.createBusinessAccount("Another Biz", "Service");
    }

    function test_CreateBusinessAccount_Revert_When_EmptyBusinessType() public {
        vm.prank(user1);
        vm.expectRevert("PAL: business type required");
        pal.createBusinessAccount("Test Biz", "");
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

    function test_RecordTransaction_Revert_When_EmptyCategory() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        vm.prank(user1);
        vm.expectRevert("PAL: category required");
        pal.recordTransaction(1 ether, "", "Test", IPAL.TransactionType.Sale);
    }

    function test_RecordExpenseTransaction() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        // First record a sale to have balance
        vm.prank(user1);
        pal.recordTransaction(
            5 ether,
            "Product Sale",
            "Initial sale",
            IPAL.TransactionType.Sale
        );

        // Then record an expense
        vm.prank(user1);
        pal.recordTransaction(
            2 ether,
            "Marketing",
            "Ad campaign",
            IPAL.TransactionType.Expense
        );

        (uint256 sales, uint256 expenses, int256 profit, uint256 balance) = pal
            .getFinancialSummary(1);
        assertEq(sales, 5 ether);
        assertEq(expenses, 2 ether);
        assertEq(profit, 3 ether);
        assertEq(balance, 3 ether);
    }

    function test_RecordPurchaseTransaction() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        // First record a sale to have balance
        vm.prank(user1);
        pal.recordTransaction(
            10 ether,
            "Product Sale",
            "Initial sale",
            IPAL.TransactionType.Sale
        );

        // Then record a purchase
        vm.prank(user1);
        pal.recordTransaction(
            3 ether,
            "Inventory",
            "Stock purchase",
            IPAL.TransactionType.Purchase
        );

        (uint256 sales, uint256 expenses, int256 profit, uint256 balance) = pal
            .getFinancialSummary(1);
        assertEq(sales, 10 ether);
        assertEq(expenses, 3 ether);
        assertEq(profit, 7 ether);
        assertEq(balance, 7 ether);
    }

    function test_AddProject() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        vm.prank(user1);
        pal.addProject(
            "Client A",
            "Website Development",
            5 ether,
            block.timestamp + 30 days
        );

        IPAL.Project[] memory projects = pal.getProjects(1);
        assertEq(projects.length, 1);
        assertEq(projects[0].clientName, "Client A");
        assertEq(projects[0].projectName, "Website Development");
        assertEq(projects[0].amount, 5 ether);
    }

    function test_AddProject_Revert_When_NoBusiness() public {
        vm.prank(user1);
        vm.expectRevert("PAL: no business account");
        pal.addProject(
            "Client A",
            "Project",
            1 ether,
            block.timestamp + 30 days
        );
    }

    function test_UpdateProjectStatus() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        vm.prank(user1);
        pal.addProject(
            "Client A",
            "Website Development",
            5 ether,
            block.timestamp + 30 days
        );

        vm.prank(user1);
        pal.updateProjectStatus(0, IPAL.ProjectStatus.Completed);

        IPAL.Project[] memory projects = pal.getProjects(1);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Completed)
        );
    }

    function test_GetBusinessInfo() public {
        vm.prank(user1);
        pal.createBusinessAccount("My Business", "E-commerce");

        IPAL.BusinessAccountInfo memory info = pal.getBusinessInfo(1);
        assertEq(info.businessId, 1);
        assertEq(info.owner, user1);
        assertEq(info.businessName, "My Business");
        assertEq(info.businessType, "E-commerce");
    }

    function test_GetBusinessInfo_Revert_When_InvalidBusinessId() public {
        vm.expectRevert("PAL: invalid business ID");
        pal.getBusinessInfo(999);
    }

    function test_GetFinancialSummary_Revert_When_InvalidBusinessId() public {
        vm.expectRevert("PAL: invalid business ID");
        pal.getFinancialSummary(999);
    }

    function test_GetProjects_Revert_When_InvalidBusinessId() public {
        vm.expectRevert("PAL: invalid business ID");
        pal.getProjects(999);
    }

    function test_GetOverdueProjects_Revert_When_InvalidBusinessId() public {
        vm.expectRevert("PAL: invalid business ID");
        pal.getOverdueProjects(999);
    }

    function test_MultipleUsersCreateBusinesses() public {
        // User1 creates business
        vm.prank(user1);
        pal.createBusinessAccount("Biz1", "Type1");
        assertEq(pal.ownerToBusinessId(user1), 1);

        // User2 creates business
        vm.prank(user2);
        pal.createBusinessAccount("Biz2", "Type2");
        assertEq(pal.ownerToBusinessId(user2), 2);

        // Verify isolation
        assertTrue(address(pal.businessAccounts(user1)) != address(0));
        assertTrue(address(pal.businessAccounts(user2)) != address(0));
        assertTrue(
            address(pal.businessAccounts(user1)) !=
                address(pal.businessAccounts(user2))
        );
    }

    function test_BusinessCounterIncrements() public {
        assertEq(pal.businessCounter(), 1);

        vm.prank(user1);
        pal.createBusinessAccount("Biz1", "Type1");
        assertEq(pal.businessCounter(), 2);

        vm.prank(user2);
        pal.createBusinessAccount("Biz2", "Type2");
        assertEq(pal.businessCounter(), 3);
    }

    function test_EmergencyPause_TeamOnly() public {
        // Non-team wallet should not be able to pause
        vm.prank(user1);
        vm.expectRevert("PAL: team only");
        pal.emergencyPause();

        // Team wallet should be able to pause
        vm.prank(teamWallet);
        pal.emergencyPause();
    }

    function test_TransactionEventsEmitted() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        // Expect transaction event
        vm.expectEmit(true, true, true, true);
        emit IPAL.TransactionRecorded(
            1, // businessId
            1 ether,
            "Product Sale",
            "Test sale",
            IPAL.TransactionType.Sale,
            block.timestamp
        );

        vm.prank(user1);
        pal.recordTransaction(
            1 ether,
            "Product Sale",
            "Test sale",
            IPAL.TransactionType.Sale
        );
    }

    function test_ProjectEventsEmitted() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        // Expect project event
        vm.expectEmit(true, true, true, true);
        emit IPAL.ProjectAdded(
            1, // businessId
            "Client A",
            "Website Dev",
            5 ether,
            block.timestamp + 30 days,
            IPAL.ProjectStatus.Active
        );

        vm.prank(user1);
        pal.addProject(
            "Client A",
            "Website Dev",
            5 ether,
            block.timestamp + 30 days
        );
    }

    function test_BusinessCreationEventEmitted() public {
        // Expect business creation event
        vm.expectEmit(true, true, true, true);
        emit IPAL.BusinessAccountCreated(
            1, // businessId
            user1,
            "Test Biz",
            "Retail",
            block.timestamp
        );

        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");
    }

    function test_FinancialCalculations() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        // Record multiple transactions
        vm.startPrank(user1);
        pal.recordTransaction(
            10 ether,
            "Sales",
            "Sale 1",
            IPAL.TransactionType.Sale
        );
        pal.recordTransaction(
            5 ether,
            "Sales",
            "Sale 2",
            IPAL.TransactionType.Sale
        );
        pal.recordTransaction(
            3 ether,
            "Expenses",
            "Expense 1",
            IPAL.TransactionType.Expense
        );
        pal.recordTransaction(
            2 ether,
            "Purchases",
            "Purchase 1",
            IPAL.TransactionType.Purchase
        );
        vm.stopPrank();

        (uint256 sales, uint256 expenses, int256 profit, uint256 balance) = pal
            .getFinancialSummary(1);

        assertEq(sales, 15 ether); // 10 + 5
        assertEq(expenses, 5 ether); // 3 + 2
        assertEq(profit, 10 ether); // 15 - 5
        assertEq(balance, 10 ether); // 15 - 5
    }

    function test_Fuzz_CreateMultipleBusinesses(uint8 count) public {
        count = uint8(bound(count, 1, 50));

        for (uint256 i = 0; i < count; i++) {
            address user = address(uint160(i + 100));
            vm.prank(user);
            pal.createBusinessAccount("Business", "Type");
        }

        assertEq(pal.businessCounter(), count + 1);
    }

    function test_Fuzz_RecordVariousTransactions(
        uint256 amount,
        uint8 txType
    ) public {
        amount = bound(amount, 1, 1000 ether);
        txType = txType % 3;

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
