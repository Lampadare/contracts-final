// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./FundingsManager.sol";
import "./ProjectManager.sol";
import "./CampaignManager.sol";
import "./TaskManager.sol";
import "./Utilities.sol";

interface Istacam {
    function getCampaign(uint256 _campaignID) external view returns (CampaignManager.Campaign memory);
    function getProject(uint256 _projectID) external view returns (ProjectManager.Project memory);
    function getTask(uint256 _taskID) external view returns (TaskManager.Task memory);
    function getApplication(uint256 _applicationID) external view returns (ProjectManager.Application memory);
}