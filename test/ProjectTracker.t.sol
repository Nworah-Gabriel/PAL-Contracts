// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ProjectTracker.sol";
import "../src/interfaces/IPal.sol";

/**
 * @title Project Tracker Unit Tests
 * @notice Tests for project management functionality
 */
contract ProjectTrackerTest is Test {
    ProjectTracker public projectTracker;

    address business1 = address(0x1);
    address business2 = address(0x2);

    function setUp() public {
        projectTracker = new ProjectTracker();
    }

    function test_AddProject() public {
        string memory clientName = "Client A";
        string memory projectName = "Website Design";
        uint256 amount = 5 ether;
        uint256 deadline = block.timestamp + 30 days;

        projectTracker.addProject(
            business1,
            clientName,
            projectName,
            amount,
            deadline
        );

        IPAL.Project[] memory projects = projectTracker.getProjects(business1);
        assertEq(projects.length, 1);
        assertEq(projects[0].clientName, clientName);
        assertEq(projects[0].projectName, projectName);
        assertEq(projects[0].amount, amount);
        assertEq(projects[0].deadline, deadline);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Active)
        );
    }

    function test_UpdateProjectStatus() public {
        // Add a project first
        projectTracker.addProject(
            business1,
            "Client A",
            "Project A",
            1 ether,
            block.timestamp + 30 days
        );

        // Update status
        projectTracker.updateProjectStatus(
            business1,
            0,
            IPAL.ProjectStatus.Completed
        );

        IPAL.Project[] memory projects = projectTracker.getProjects(business1);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Completed)
        );
    }

    function test_GetOverdueProjects() public {
        // Warp time to avoid underflow
        vm.warp(100 days);

        // Add a project with past deadline
        uint256 pastDeadline = block.timestamp - 1 days;
        projectTracker.addProject(
            business1,
            "Client A",
            "Overdue Project",
            1 ether,
            pastDeadline
        );

        IPAL.Project[] memory overdueProjects = projectTracker
            .getOverdueProjects(business1);
        assertEq(overdueProjects.length, 1);
        assertEq(overdueProjects[0].projectName, "Overdue Project");
    }

    function test_ProjectAutoOverdue() public {
        // Warp time to avoid underflow
        vm.warp(100 days);

        // Add a project with past deadline
        uint256 pastDeadline = block.timestamp - 1 days;
        projectTracker.addProject(
            business1,
            "Client A",
            "Auto Overdue Project",
            1 ether,
            pastDeadline
        );

        // The project should automatically be marked as overdue when retrieved
        IPAL.Project[] memory overdueProjects = projectTracker
            .getOverdueProjects(business1);
        assertEq(overdueProjects.length, 1);
        assertEq(overdueProjects[0].projectName, "Auto Overdue Project");
        assertEq(
            uint256(overdueProjects[0].status),
            uint256(IPAL.ProjectStatus.Overdue)
        );
    }

    function test_MultipleProjects() public {
        // Add multiple projects
        projectTracker.addProject(
            business1,
            "Client A",
            "Project A",
            1 ether,
            block.timestamp + 30 days
        );
        projectTracker.addProject(
            business1,
            "Client B",
            "Project B",
            2 ether,
            block.timestamp + 60 days
        );
        projectTracker.addProject(
            business1,
            "Client C",
            "Project C",
            3 ether,
            block.timestamp + 90 days
        );

        IPAL.Project[] memory projects = projectTracker.getProjects(business1);
        assertEq(projects.length, 3);
        assertEq(projects[0].clientName, "Client A");
        assertEq(projects[1].clientName, "Client B");
        assertEq(projects[2].clientName, "Client C");
    }

    function test_BusinessIsolation() public {
        // Add project for business1
        projectTracker.addProject(
            business1,
            "Client A",
            "Project A",
            1 ether,
            block.timestamp + 30 days
        );

        // Add project for business2
        projectTracker.addProject(
            business2,
            "Client B",
            "Project B",
            2 ether,
            block.timestamp + 60 days
        );

        // Verify isolation
        IPAL.Project[] memory projects1 = projectTracker.getProjects(business1);
        IPAL.Project[] memory projects2 = projectTracker.getProjects(business2);

        assertEq(projects1.length, 1);
        assertEq(projects2.length, 1);
        assertEq(projects1[0].clientName, "Client A");
        assertEq(projects2[0].clientName, "Client B");
    }

    function test_UpdateProjectStatus_Revert_When_InvalidProjectId() public {
        // Add a project first
        projectTracker.addProject(
            business1,
            "Client A",
            "Project A",
            1 ether,
            block.timestamp + 30 days
        );

        // Try to update non-existent project
        vm.expectRevert("ProjectTracker: invalid project ID");
        projectTracker.updateProjectStatus(
            business1,
            999,
            IPAL.ProjectStatus.Completed
        );
    }

    function test_AddProject_Revert_When_InvalidParameters() public {
        // Test each invalid parameter separately to avoid the depth issue

        // Test empty client name
        vm.expectRevert("ProjectTracker: client name required");
        projectTracker.addProject(
            business1,
            "",
            "Project",
            1 ether,
            block.timestamp + 30 days
        );

        // Reset expectations
        vm.expectRevert("ProjectTracker: project name required");
        projectTracker.addProject(
            business1,
            "Client",
            "",
            1 ether,
            block.timestamp + 30 days
        );

        // Reset expectations
        vm.expectRevert("ProjectTracker: amount must be positive");
        projectTracker.addProject(
            business1,
            "Client",
            "Project",
            0,
            block.timestamp + 30 days
        );

        // Warp time to avoid underflow
        vm.warp(100 days);

        // Reset expectations
        vm.expectRevert("ProjectTracker: deadline must be in future");
        projectTracker.addProject(
            business1,
            "Client",
            "Project",
            1 ether,
            block.timestamp - 1 days
        );
    }
}
