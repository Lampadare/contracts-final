// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";

interface IStandardSubstrate {
    function getCampaign(
        uint256 _campaignID
    ) external view returns (CampaignManager.Campaign memory);

    function getProject(
        uint256 _projectID
    ) external view returns (ProjectManager.Project memory);

    function getTask(
        uint256 _taskID
    ) external view returns (TaskManager.Task memory);

    function getApplication(
        uint256 _applicationID
    ) external view returns (ProjectManager.Application memory);

    function getDecisionTimes()
        external
        view
        returns (uint256, uint256, uint256, uint256);
}
