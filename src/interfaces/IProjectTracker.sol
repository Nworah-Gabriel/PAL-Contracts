// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IPAL} from "@interface/IPal.sol";

interface IProjectTracker {
    event ProjectAdded(
        address indexed business,
        uint256 indexed projectId,
        string clientName,
        string projectName,
        uint256 amount,
        uint256 deadline,
        IPAL.ProjectStatus status
    );

    event ProjectStatusUpdated(
        address indexed business,
        uint256 indexed projectId,
        IPAL.ProjectStatus newStatus,
        uint256 timestamp
    );

    event ProjectOverdue(
        address indexed business,
        uint256 indexed projectId,
        uint256 timestamp
    );

    function addProject(
        address _business,
        string calldata _clientName,
        string calldata _projectName,
        uint256 _amount,
        uint256 _deadline
    ) external;

    function updateProjectStatus(
        address _business,
        uint256 _projectId,
        IPAL.ProjectStatus _newStatus
    ) external;

    function getProjects(
        address _business
    ) external view returns (IPAL.Project[] memory);

    function getOverdueProjects(
        address _business
    ) external view returns (IPAL.Project[] memory);
}