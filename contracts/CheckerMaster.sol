// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";
import "./IStandardSubstrate.sol";

contract CheckerMaster {
    // Link standard campaign contract
    address public standardSubstrateAddress = address(0);

    constructor(address _standardSubstrateAddress) {
        require(
            standardSubstrateAddress == address(0),
            "standardSubstrateAddress must be set once"
        );
        standardSubstrateAddress = _standardSubstrateAddress;
    }

    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    // No Return, Just Require
    // Existance
    function requireCampaignExisting(uint256 _campaignID) public view {
        require(isCampaignExisting(_campaignID), "Campaign does not exist");
    }

    function requireProjectExisting(uint256 _projectID) public view {
        require(isProjectExisting(_projectID), "Project does not exist");
    }

    function requireTaskExisting(uint256 _taskID) public view {
        require(isTaskExisting(_taskID), "Task does not exist");
    }

    function requireApplicationExisting(uint256 _applicationID) public view {
        require(
            isApplicationExisting(_applicationID),
            "Application does not exist"
        );
    }

    ///////////////////////
    // Roles
    // Campaigns --------------------
    function requireCampaignCreator(
        uint256 _campaignID,
        address _address
    ) public view {
        require(
            isCampaignCreator(_campaignID, _address),
            "Address is not campaign creator"
        );
    }

    function requireCampaignOwner(
        uint256 _campaignID,
        address _address
    ) public view {
        require(
            isCampaignOwner(_campaignID, _address),
            "Address is not campaign owner"
        );
    }

    function requireCampaignAcceptor(
        uint256 _campaignID,
        address _address
    ) public view {
        require(
            isCampaignAcceptor(_campaignID, _address),
            "Address is not campaign acceptor"
        );
    }

    function requireCampaignFunder(
        uint256 _campaignID,
        address _address
    ) public view {
        require(
            isCampaignFunder(_campaignID, _address),
            "Address is not campaign funder"
        );
    }

    function requireCampaignStakeholder(
        uint256 _campaignID,
        address _address
    ) public view {
        require(
            isCampaignStakeholder(_campaignID, _address),
            "Address is not campaign stakeholder"
        );
    }

    // Projects --------------------
    function requireWorkerOnProject(
        uint256 _projectID,
        address _address
    ) public view {
        require(
            isWorkerOnProject(_projectID, _address),
            "Address is not worker on project"
        );
    }

    function requirePastWorkerOnProject(
        uint256 _projectID,
        address _address
    ) public view {
        require(
            isPastWorkerOnProject(_projectID, _address),
            "Address is not past worker on project"
        );
    }

    // Tasks --------------------
    function requireWorkerOnTask(
        uint256 _taskID,
        address _address
    ) public view {
        require(
            isWorkerOnTask(_taskID, _address),
            "Address is not worker on task"
        );
    }

    ///////////////////////
    // Campaign Status
    function requireCampaignRunning(uint256 _campaignID) public view {
        require(
            isCampaignRunning(_campaignID),
            "Campaign is not running or is not funded"
        );
    }

    ///////////////////////
    // Project Status
    function requireProjectRunning(uint256 _projectID) public view {
        require(
            isProjectRunning(_projectID),
            "Project is not running or is not funded"
        );
    }

    function requireProjectClosed(uint256 _projectID) public view {
        require(
            isProjectClosed(_projectID),
            "Project is not closed or is not funded"
        );
    }

    function requireProjectStage(uint256 _projectID) public view {
        require(
            isProjectStage(_projectID),
            "Project is not in the required stage"
        );
    }

    function requireProjectGate(uint256 _projectID) public view {
        require(
            isProjectGate(_projectID),
            "Project is not in the required gate"
        );
    }

    function requireProjectPostSub(uint256 _projectID) public view {
        require(
            isProjectPostSub(_projectID),
            "Project is not in the required post-submission stage"
        );
    }

    function requireProjectPostDisp(uint256 _projectID) public view {
        require(
            isProjectPostDisp(_projectID),
            "Project is not in the required post-dispute stage"
        );
    }

    function requireProjectSettled(uint256 _projectID) public view {
        require(
            isProjectSettled(_projectID),
            "Project is not in the required settled stage"
        );
    }

    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    // Returns Boolean
    // Existance
    function isCampaignExisting(
        uint256 _campaignID
    ) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getCampaign(_campaignID)
                .creationTime == 0
        ) {
            return false;
        } else {
            return true;
        }
    }

    function isProjectExisting(uint256 _projectID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getProject(_projectID)
                .creationTime == 0
        ) {
            return false;
        } else {
            return true;
        }
    }

    function isTaskExisting(uint256 _taskID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getTask(_taskID)
                .creationTime == 0
        ) {
            return false;
        } else {
            return true;
        }
    }

    function isApplicationExisting(
        uint256 _applicationID
    ) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getApplication(_applicationID)
                .applicant == address(0)
        ) {
            return false;
        } else {
            return true;
        }
    }

    ///////////////////////
    // Roles
    // Campaigns --------------------
    function isCampaignCreator(
        uint256 _campaignID,
        address _address
    ) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getCampaign(_campaignID)
                .creator == _address
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isCampaignOwner(
        uint256 _campaignID,
        address _address
    ) public view returns (bool) {
        address payable[] memory owners = IStandardSubstrate(
            standardSubstrateAddress
        ).getCampaign(_campaignID).owners;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function isCampaignAcceptor(
        uint256 _campaignID,
        address _address
    ) public view returns (bool) {
        address payable[] memory acceptors = IStandardSubstrate(
            standardSubstrateAddress
        ).getCampaign(_campaignID).acceptors;
        for (uint256 i = 0; i < acceptors.length; i++) {
            if (acceptors[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function isCampaignFunder(
        uint256 _campaignID,
        address _address
    ) public view returns (bool) {
        FundingsManager.Fundings[] memory fundings = IStandardSubstrate(
            standardSubstrateAddress
        ).getCampaign(_campaignID).fundings;
        for (uint256 i = 0; i < fundings.length; i++) {
            if (fundings[i].funder == _address) {
                return true;
            }
        }
        return false;
    }

    function isCampaignStakeholder(
        uint256 _campaignID,
        address _address
    ) public view returns (bool) {
        address payable[] memory stakeholders = IStandardSubstrate(
            standardSubstrateAddress
        ).getCampaign(_campaignID).allTimeStakeholders;
        for (uint256 i = 0; i < stakeholders.length; i++) {
            if (stakeholders[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Projects --------------------
    function isWorkerOnProject(
        uint256 _projectID,
        address _address
    ) public view returns (bool) {
        address[] memory workers = IStandardSubstrate(standardSubstrateAddress)
            .getProject(_projectID)
            .workers;
        for (uint256 i = 0; i < workers.length; i++) {
            if (workers[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function isPastWorkerOnProject(
        uint256 _projectID,
        address _address
    ) public view returns (bool) {
        address[] memory pastWorkers = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID).pastWorkers;
        for (uint256 i = 0; i < pastWorkers.length; i++) {
            if (pastWorkers[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Tasks --------------------
    function isWorkerOnTask(
        uint256 _taskID,
        address _address
    ) public view returns (bool) {
        address worker = IStandardSubstrate(standardSubstrateAddress)
            .getTask(_taskID)
            .worker;
        if (worker == _address) {
            return true;
        }
        return false;
    }

    ///////////////////////
    // Campaign Status
    function isCampaignRunning(uint256 _campaignID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getCampaign(_campaignID)
                .status == CampaignManager.CampaignStatus.Running
        ) {
            return true;
        } else {
            return false;
        }
    }

    ///////////////////////
    // Project Status
    function isProjectRunning(uint256 _projectID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getProject(_projectID)
                .status != ProjectManager.ProjectStatus.Closed
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isProjectClosed(uint256 _projectID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getProject(_projectID)
                .status == ProjectManager.ProjectStatus.Closed
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isProjectStage(uint256 _projectID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getProject(_projectID)
                .status == ProjectManager.ProjectStatus.Stage
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isProjectGate(uint256 _projectID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getProject(_projectID)
                .status == ProjectManager.ProjectStatus.Gate
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isProjectPostSub(uint256 _projectID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getProject(_projectID)
                .status == ProjectManager.ProjectStatus.PostSub
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isProjectPostDisp(uint256 _projectID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getProject(_projectID)
                .status == ProjectManager.ProjectStatus.PostDisp
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isProjectSettled(uint256 _projectID) public view returns (bool) {
        if (
            IStandardSubstrate(standardSubstrateAddress)
                .getProject(_projectID)
                .status == ProjectManager.ProjectStatus.Settled
        ) {
            return true;
        } else {
            return false;
        }
    }
}
