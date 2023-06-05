// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";

interface ICheckerMaster {
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    // No Return, Just Require
    // Existance
    function requireCampaignExisting(uint256 _campaignID) external view;

    function requireProjectExisting(uint256 _projectID) external view;

    function requireTaskExisting(uint256 _taskID) external view;

    function requireApplicationExisting(uint256 _applicationID) external view;

    // Roles
    // Campaigns --------------------
    function requireCampaignCreator(
        uint256 _campaignID,
        address _address
    ) external view;

    function requireCampaignOwner(
        uint256 _campaignID,
        address _address
    ) external view;

    function requireCampaignAcceptor(
        uint256 _campaignID,
        address _address
    ) external view;

    function requireCampaignFunder(
        uint256 _campaignID,
        address _address
    ) external view;

    function requireCampaignStakeholder(
        uint256 _campaignID,
        address _address
    ) external view;

    // Projects --------------------
    function requireWorkerOnProject(
        uint256 _projectID,
        address _address
    ) external view;

    function requirePastWorkerOnProject(
        uint256 _projectID,
        address _address
    ) external view;

    // Tasks --------------------
    function requireWorkerOnTask(
        uint256 _taskID,
        address _address
    ) external view;

    ///////////////////////
    // Campaign Status
    function requireCampaignRunning(uint256 _campaignID) external view;

    ///////////////////////
    // Project Status
    function requireProjectRunning(uint256 _projectID) external view;

    function requireProjectClosed(uint256 _projectID) external view;

    function requireProjectStage(uint256 _projectID) external view;

    function requireProjectGate(uint256 _projectID) external view;

    function requireProjectPostSub(uint256 _projectID) external view;

    function requireProjectPostDisp(uint256 _projectID) external view;

    function requireProjectSettled(uint256 _projectID) external view;

    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    // Returns Boolean

    ///////////////////////
    // Existance
    function isCampaignExisting(
        uint256 _campaignID
    ) external view returns (bool);

    function isProjectExisting(uint256 _projectID) external view returns (bool);

    function isTaskExisting(uint256 _taskID) external view returns (bool);

    function isApplicationExisting(
        uint256 _applicationID
    ) external view returns (bool);

    ///////////////////////
    // Roles
    // Campaigns --------------------
    function isCampaignCreator(
        uint256 _campaignID,
        address _address
    ) external view returns (bool);

    function isCampaignOwner(
        uint256 _campaignID,
        address _address
    ) external view returns (bool);

    function isCampaignAcceptor(
        uint256 _campaignID,
        address _address
    ) external view returns (bool);

    function isCampaignFunder(
        uint256 _campaignID,
        address _address
    ) external view returns (bool);

    function isCampaignStakeholder(
        uint256 _campaignID,
        address _address
    ) external view returns (bool);

    // Projects --------------------
    function isWorkerOnProject(
        uint256 _projectID,
        address _address
    ) external view returns (bool);

    function isPastWorkerOnProject(
        uint256 _projectID,
        address _address
    ) external view returns (bool);

    // Tasks --------------------
    function isWorkerOnTask(
        uint256 _taskID,
        address _address
    ) external view returns (bool);

    ///////////////////////
    // Campaign Status
    function isCampaignRunning(
        uint256 _campaignID
    ) external view returns (bool);

    ///////////////////////
    // Project Status
    function isProjectRunning(uint256 _projectID) external view returns (bool);

    function isProjectClosed(uint256 _projectID) external view returns (bool);

    function isProjectStage(uint256 _projectID) external view returns (bool);

    function isProjectGate(uint256 _projectID) external view returns (bool);

    function isProjectPostSub(uint256 _projectID) external view returns (bool);

    function isProjectPostDisp(uint256 _projectID) external view returns (bool);

    function isProjectSettled(uint256 _projectID) external view returns (bool);
}
