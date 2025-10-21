// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@forge-std/Test.sol";
import "@contract/PalCore.sol";

/**
 * @author Nworah Chimzuruoke Gabriel (SAGGIO)
 * @title PAL Integration Tests
 * @notice Tests interaction between different contract components
 * @dev Tests complete workflows and cross-contract functionality
 */
contract PALIntegrationTest is Test {
    PalCore public pal;

    address teamWallet = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function setUp() public {
        pal = new PalCore(teamWallet);
    }

    function test_CompleteBusinessWorkflow() public {
        // Create business
        vm.prank(user1);
        pal.createBusinessAccount("My Business", "E-commerce");

        // Record transactions
        vm.startPrank(user1);
        pal.recordTransaction(
            5 ether,
            "Product Sales",
            "Q1 Sales",
            IPAL.TransactionType.Sale
        );
        pal.recordTransaction(
            2 ether,
            "Marketing",
            "Ad Campaign",
            IPAL.TransactionType.Expense
        );
        pal.recordTransaction(
            1 ether,
            "Operations",
            "Office Rent",
            IPAL.TransactionType.Expense
        );

        // Add project
        pal.addProject(
            "Client A",
            "Website Development",
            10 ether,
            block.timestamp + 60 days
        );
        vm.stopPrank();

        // Verify financial summary
        (uint256 sales, uint256 expenses, int256 profit, uint256 balance) = pal
            .getFinancialSummary(1);

        assertEq(sales, 5 ether);
        assertEq(expenses, 3 ether);
        assertEq(profit, 2 ether);
        assertEq(balance, 2 ether);

        // Verify project was added
        IPAL.Project[] memory projects = pal.getProjects(1);
        assertEq(projects.length, 1);
        assertEq(projects[0].clientName, "Client A");
        assertEq(projects[0].projectName, "Website Development");
    }

    function test_ProjectManagementWorkflow() public {
        vm.prank(user1);
        pal.createBusinessAccount("Agency", "Creative");

        uint256 deadline = block.timestamp + 30 days;

        vm.prank(user1);
        pal.addProject("Client A", "Website Redesign", 5 ether, deadline);

        // Verify project creation
        IPAL.Project[] memory projects = pal.getProjects(1);
        assertEq(projects.length, 1);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Active)
        );

        // Update project status
        vm.prank(user1);
        pal.updateProjectStatus(0, IPAL.ProjectStatus.Completed);

        // Verify status update
        projects = pal.getProjects(1);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Completed)
        );
    }

    function test_MultipleBusinessesIsolation() public {
        // User1 creates business
        vm.prank(user1);
        pal.createBusinessAccount("Biz1", "Type1");

        // User2 creates business
        vm.prank(user2);
        pal.createBusinessAccount("Biz2", "Type2");

        // User1 records transaction
        vm.prank(user1);
        pal.recordTransaction(
            10 ether,
            "Sales",
            "Sale1",
            IPAL.TransactionType.Sale
        );

        // User2 records transaction
        vm.prank(user2);
        pal.recordTransaction(
            5 ether,
            "Sales",
            "Sale2",
            IPAL.TransactionType.Sale
        );

        // Verify isolation
        (uint256 sales1, , , ) = pal.getFinancialSummary(1);
        (uint256 sales2, , , ) = pal.getFinancialSummary(2);

        assertEq(sales1, 10 ether);
        assertEq(sales2, 5 ether);
    }

    function test_AlertSystemIntegration() public {
        vm.prank(user1);
        pal.createBusinessAccount("Test Biz", "Retail");

        // Record low balance scenario
        vm.prank(user1);
        pal.recordTransaction(
            0.05 ether,
            "Small Sale",
            "Test",
            IPAL.TransactionType.Sale
        );

        // Should trigger low balance alert
        // Alert verification would be implemented when event listening is added

        // Verify the transaction was recorded
        (uint256 sales, , , uint256 balance) = pal.getFinancialSummary(1);
        assertEq(sales, 0.05 ether);
        assertEq(balance, 0.05 ether);
    }
}
