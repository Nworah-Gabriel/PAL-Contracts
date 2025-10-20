// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IProjectTracker} from "./interfaces/IProjectTracker.sol";
import {IPAL} from "./interfaces/IPal.sol";

/**
 * @title Project Tracker Contract
 * @notice Handles client and project management for businesses
 * @dev Stores project data, deadlines, and status information
 */
contract ProjectTracker is IProjectTracker {
    // Storage
    mapping(address => IPAL.Project[]) public businessProjects;
    mapping(address => uint256) public projectCounters;

    /**
     * @notice Adds a new project for a business
     * @dev Only callable by main PAL contract
     * @param _business Business account address
     * @param _clientName Name of the client
     * @param _projectName Name of the project
     * @param _amount Project amount
     * @param _deadline Project deadline timestamp
     */
    function addProject(
        address _business,
        string calldata _clientName,
        string calldata _projectName,
        uint256 _amount,
        uint256 _deadline
    ) external override {
        require(
            _business != address(0),
            "ProjectTracker: business cannot be zero"
        );
        require(
            bytes(_clientName).length > 0,
            "ProjectTracker: client name required"
        );
        require(
            bytes(_projectName).length > 0,
            "ProjectTracker: project name required"
        );
        require(_amount > 0, "ProjectTracker: amount must be positive");
        require(
            _deadline > block.timestamp,
            "ProjectTracker: deadline must be in future"
        );

        uint256 projectId = projectCounters[_business];

        IPAL.Project memory newProject = IPAL.Project({
            id: projectId,
            clientName: _clientName,
            projectName: _projectName,
            amount: _amount,
            deadline: _deadline,
            status: IPAL.ProjectStatus.Active,
            createdAt: block.timestamp
        });

        businessProjects[_business].push(newProject);
        projectCounters[_business]++;

        emit ProjectAdded(
            _business,
            projectId,
            _clientName,
            _projectName,
            _amount,
            _deadline,
            IPAL.ProjectStatus.Active
        );
    }

    /**
     * @notice Updates project status
     * @dev Only callable by main PAL contract
     * @param _business Business account address
     * @param _projectId Project ID to update
     * @param _newStatus New project status
     */
    function updateProjectStatus(
        address _business,
        uint256 _projectId,
        IPAL.ProjectStatus _newStatus
    ) external override {
        require(
            _business != address(0),
            "ProjectTracker: business cannot be zero"
        );
        require(
            _projectId < businessProjects[_business].length,
            "ProjectTracker: invalid project ID"
        );

        IPAL.Project storage project = businessProjects[_business][_projectId];
        project.status = _newStatus;

        emit ProjectStatusUpdated(
            _business,
            _projectId,
            _newStatus,
            block.timestamp
        );

        // Check for overdue status
        if (
            _newStatus == IPAL.ProjectStatus.Active &&
            block.timestamp > project.deadline
        ) {
            project.status = IPAL.ProjectStatus.Overdue;
            emit ProjectOverdue(_business, _projectId, block.timestamp);
        }
    }

    /**
     * @notice Gets all projects for a business
     * @param _business Business account address
     * @return Array of projects
     */
    function getProjects(
        address _business
    ) external view override returns (IPAL.Project[] memory) {
        return businessProjects[_business];
    }

    /**
     * @notice Gets overdue projects for a business
     * @param _business Business account address
     * @return Array of overdue projects
     */
    function getOverdueProjects(
        address _business
    ) external view override returns (IPAL.Project[] memory) {
        uint256 totalProjects = businessProjects[_business].length;
        uint256 overdueCount = 0;

        // First count overdue projects
        for (uint256 i = 0; i < totalProjects; i++) {
            if (
                businessProjects[_business][i].status ==
                IPAL.ProjectStatus.Overdue ||
                (businessProjects[_business][i].status ==
                    IPAL.ProjectStatus.Active &&
                    block.timestamp > businessProjects[_business][i].deadline)
            ) {
                overdueCount++;
            }
        }

        // Create result array
        IPAL.Project[] memory overdueProjects = new IPAL.Project[](
            overdueCount
        );
        uint256 currentIndex = 0;

        // Fill result array
        for (uint256 i = 0; i < totalProjects; i++) {
            IPAL.Project memory project = businessProjects[_business][i];
            if (
                project.status == IPAL.ProjectStatus.Overdue ||
                (project.status == IPAL.ProjectStatus.Active &&
                    block.timestamp > project.deadline)
            ) {
                overdueProjects[currentIndex] = project;
                currentIndex++;
            }
        }

        return overdueProjects;
    }
}
