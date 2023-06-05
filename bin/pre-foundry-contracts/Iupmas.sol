// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";

interface Iupmas {
    function toStageConditions(uint256 _projectID) external view returns (bool);

    function toGateConditions(uint256 _projectID) external view returns (bool);

    function toPostSubConditions(
        uint256 _projectID
    ) external view returns (bool);

    function toPostDispConditions(
        uint256 _projectID
    ) external view returns (bool);

    function toSettledConditions(
        uint256 _projectID
    ) external view returns (bool);

    function toClosedConditions(
        uint256 _projectID
    ) external view returns (bool);

    function computeProjectReward(
        uint256 _projectID
    ) external view returns (uint256);

    // GETTERS
    function getPendingTasksIDs(
        uint256 _projectID
    ) external view returns (uint256[] memory);

    function getDeclinedTasksIDs(
        uint256 _projectID
    ) external view returns (uint256[] memory);

    function getNoneTasksIDs(
        uint256 _projectID
    ) external view returns (uint256[] memory);

    // WHERE TO GO
    function whereToGo(
        uint256 _projectID
    )
        external
        view
        returns (bool isGoing, ProjectManager.ProjectStatus goingTo);
}
