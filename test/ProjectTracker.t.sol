// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@forge-std/Test.sol";
import "@contract/ProjectTracker.sol";
import "@interface/IPal.sol";

/**
 * @author Nworah Chimzuruoke Gabriel (SAGGIO)
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
        // Add a project with future deadline first
        projectTracker.addProject(
            business1,
            "Client A",
            "Future Project",
            1 ether,
            block.timestamp + 30 days
        );

        // Warp time to make the project overdue
        vm.warp(block.timestamp + 31 days);

        IPAL.Project[] memory overdueProjects = projectTracker
            .getOverdueProjects(business1);
        assertEq(overdueProjects.length, 1);
        assertEq(overdueProjects[0].projectName, "Future Project");
        // Status should still be Active in storage, but detected as overdue in the function
    }

    function test_ProjectAutoOverdue() public {
        // Add a project with future deadline
        projectTracker.addProject(
            business1,
            "Client A",
            "Auto Overdue Project",
            1 ether,
            block.timestamp + 30 days
        );

        // Warp time to make it overdue
        vm.warp(block.timestamp + 31 days);

        // The project should be detected as overdue when retrieved
        IPAL.Project[] memory overdueProjects = projectTracker
            .getOverdueProjects(business1);
        assertEq(overdueProjects.length, 1);
        assertEq(overdueProjects[0].projectName, "Auto Overdue Project");
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

    // SEPARATE REVERT TESTS TO AVOID DEPTH ISSUES

    function test_AddProject_Revert_When_EmptyClientName() public {
        vm.expectRevert("ProjectTracker: client name required");
        projectTracker.addProject(
            business1,
            "",
            "Project",
            1 ether,
            block.timestamp + 30 days
        );
    }

    function test_AddProject_Revert_When_EmptyProjectName() public {
        vm.expectRevert("ProjectTracker: project name required");
        projectTracker.addProject(
            business1,
            "Client",
            "",
            1 ether,
            block.timestamp + 30 days
        );
    }

    function test_AddProject_Revert_When_ZeroAmount() public {
        vm.expectRevert("ProjectTracker: amount must be positive");
        projectTracker.addProject(
            business1,
            "Client",
            "Project",
            0,
            block.timestamp + 30 days
        );
    }

    function test_AddProject_Revert_When_PastDeadline() public {
    // Warp to a future time first to avoid underflow
    vm.warp(100 days);
    
    vm.expectRevert("ProjectTracker: deadline must be in future");
    projectTracker.addProject(
        business1,
        "Client",
        "Project",
        1 ether,
        block.timestamp - 1 days
    );
}

    // ZERO ADDRESS PROTECTION TESTS

    function test_AddProject_Revert_When_ZeroAddress() public {
        vm.expectRevert("ProjectTracker: business cannot be zero");
        projectTracker.addProject(
            address(0),
            "Client A",
            "Project",
            1 ether,
            block.timestamp + 30 days
        );
    }

    function test_UpdateProjectStatus_Revert_When_ZeroAddress() public {
        vm.expectRevert("ProjectTracker: business cannot be zero");
        projectTracker.updateProjectStatus(
            address(0),
            0,
            IPAL.ProjectStatus.Completed
        );
    }

    function test_GetProjects_Revert_When_ZeroAddress() public {
        vm.expectRevert("ProjectTracker: business cannot be zero");
        projectTracker.getProjects(address(0));
    }

    function test_GetOverdueProjects_Revert_When_ZeroAddress() public {
        vm.expectRevert("ProjectTracker: business cannot be zero");
        projectTracker.getOverdueProjects(address(0));
    }

    // EXISTING ADDITIONAL TESTS (keep these as they're working)

    function test_ProjectStatusFlow() public {
        // Test complete project status flow: Active -> Completed
        projectTracker.addProject(
            business1,
            "Client A",
            "Status Flow Project",
            1 ether,
            block.timestamp + 30 days
        );

        IPAL.Project[] memory projects = projectTracker.getProjects(business1);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Active)
        );

        // Update to Completed
        projectTracker.updateProjectStatus(
            business1,
            0,
            IPAL.ProjectStatus.Completed
        );

        projects = projectTracker.getProjects(business1);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Completed)
        );

        // Update to Cancelled
        projectTracker.updateProjectStatus(
            business1,
            0,
            IPAL.ProjectStatus.Cancelled
        );

        projects = projectTracker.getProjects(business1);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Cancelled)
        );
    }

    function test_OverdueDetectionOnStatusUpdate() public {
        // Add a project
        projectTracker.addProject(
            business1,
            "Client A",
            "Overdue Detection",
            1 ether,
            block.timestamp + 30 days
        );

        // Warp time to make it overdue
        vm.warp(block.timestamp + 31 days);

        // Try to set status to Active (should become Overdue)
        projectTracker.updateProjectStatus(
            business1,
            0,
            IPAL.ProjectStatus.Active
        );

        IPAL.Project[] memory projects = projectTracker.getProjects(business1);
        assertEq(
            uint256(projects[0].status),
            uint256(IPAL.ProjectStatus.Overdue)
        );
    }

    function test_GetOverdueProjects_Empty() public {
        // Test when there are no overdue projects
        projectTracker.addProject(
            business1,
            "Client A",
            "Active Project",
            1 ether,
            block.timestamp + 30 days
        );

        IPAL.Project[] memory overdueProjects = projectTracker
            .getOverdueProjects(business1);
        assertEq(overdueProjects.length, 0);
    }

    function test_ProjectCounterIncrement() public {
        // Test that project counters increment correctly
        assertEq(projectTracker.projectCounters(business1), 0);

        projectTracker.addProject(
            business1,
            "Client A",
            "Project 1",
            1 ether,
            block.timestamp + 30 days
        );
        assertEq(projectTracker.projectCounters(business1), 1);

        projectTracker.addProject(
            business1,
            "Client B",
            "Project 2",
            2 ether,
            block.timestamp + 60 days
        );
        assertEq(projectTracker.projectCounters(business1), 2);
    }

    function test_ProjectIdsAreSequential() public {
        // Test that project IDs are assigned sequentially
        projectTracker.addProject(
            business1,
            "Client A",
            "Project 1",
            1 ether,
            block.timestamp + 30 days
        );
        projectTracker.addProject(
            business1,
            "Client B",
            "Project 2",
            2 ether,
            block.timestamp + 60 days
        );
        projectTracker.addProject(
            business1,
            "Client C",
            "Project 3",
            3 ether,
            block.timestamp + 90 days
        );

        IPAL.Project[] memory projects = projectTracker.getProjects(business1);
        assertEq(projects[0].id, 0);
        assertEq(projects[1].id, 1);
        assertEq(projects[2].id, 2);
    }

    function test_MixedOverdueAndActiveProjects() public {
        // Add mixed projects
        projectTracker.addProject(
            business1,
            "Client A",
            "Active Project",
            1 ether,
            block.timestamp + 30 days
        );
        projectTracker.addProject(
            business1,
            "Client B",
            "Completed Project",
            2 ether,
            block.timestamp + 60 days
        );

        // Warp time and add an overdue project
        vm.warp(block.timestamp + 31 days);
        projectTracker.addProject(
            business1,
            "Client C",
            "Future Project",
            3 ether,
            block.timestamp + 30 days
        );

        // Set second project to completed
        projectTracker.updateProjectStatus(
            business1,
            1,
            IPAL.ProjectStatus.Completed
        );

        // First project should be overdue now
        IPAL.Project[] memory overdueProjects = projectTracker
            .getOverdueProjects(business1);
        assertEq(overdueProjects.length, 1);
        assertEq(overdueProjects[0].projectName, "Active Project");
    }

    function test_ProjectEventsEmitted() public {
        // Test that events are properly emitted
        vm.expectEmit(true, true, true, true);
        emit IProjectTracker.ProjectAdded(
            business1,
            0,
            "Client A",
            "Event Test Project",
            1 ether,
            block.timestamp + 30 days,
            IPAL.ProjectStatus.Active
        );

        projectTracker.addProject(
            business1,
            "Client A",
            "Event Test Project",
            1 ether,
            block.timestamp + 30 days
        );
    }

    function test_OverdueEventEmitted() public {
        // Add a project
        projectTracker.addProject(
            business1,
            "Client A",
            "Overdue Event Test",
            1 ether,
            block.timestamp + 30 days
        );

        // Warp time to make it overdue
        vm.warp(block.timestamp + 31 days);

        // Expect overdue event when updating status to Active
        vm.expectEmit(true, true, true, true);
        emit IProjectTracker.ProjectOverdue(business1, 0, block.timestamp);

        projectTracker.updateProjectStatus(
            business1,
            0,
            IPAL.ProjectStatus.Active
        );
    }

    function test_ProjectDataPersistence() public {
        // Test that project data persists correctly
        string memory clientName = "Persistent Client";
        string memory projectName = "Persistent Project";
        uint256 amount = 5 ether;
        uint256 deadline = block.timestamp + 30 days;

        projectTracker.addProject(
            business1,
            clientName,
            projectName,
            amount,
            deadline
        );

        // Retrieve and verify data persistence
        IPAL.Project[] memory projects = projectTracker.getProjects(business1);
        assertEq(projects[0].clientName, clientName);
        assertEq(projects[0].projectName, projectName);
        assertEq(projects[0].amount, amount);
        assertEq(projects[0].deadline, deadline);
        assertEq(projects[0].createdAt, block.timestamp);
    }
}
