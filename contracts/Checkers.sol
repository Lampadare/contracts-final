// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./FundingsManager.sol";
import "./ProjectManager.sol";
import "./CampaignManager.sol";
import "./TaskManager.sol";
import "./Utilities.sol";
import "./Istacam.sol";

contract Checkers {
    address public standardCampaignAddress = address(0);

    constructor (address _standardCampaignAddress) {
        require (standardCampaignAddress == address(0), "standardCampaignAddress must be set once");
        standardCampaignAddress = _standardCampaignAddress;
    }

    // Conditions for going to Stage ✅
    function toStageConditions(uint256 _projectID) public view returns (bool, bool) {
        ProjectManager.Project memory project = Istacam(standardCampaignAddress).getProject(_projectID);

        // Conditions for normal to stage
        bool currentStatusValid = project.status ==
            ProjectManager.ProjectStatus.Settled;
        bool projectHasWorkers = project.workers.length > 0;
        bool inStagePeriod = block.timestamp >=
            project.nextMilestone.startStageTimestamp;

        // For fast forward to stage
        bool fastForwarding = false; // checkFastForwardStatus(_projectID);
        bool stillInSettledPeriod = block.timestamp <
            project.nextMilestone.startStageTimestamp;
        bool allTasksHaveWorkers = true;

        // Ensure all tasks have workers
        if (fastForwarding) {
            for (uint256 i = 0; i < project.childTasks.length; i++) {
                // Get the task and check if it has a worker
                if (Istacam(standardCampaignAddress).getTask(project.childTasks[i]).worker == address(0)) {
                    allTasksHaveWorkers = false;
                    return (false, false);
                }
            }
        }

        // All conditions must be true to go to stage
        return (
            currentStatusValid && projectHasWorkers && inStagePeriod,
            currentStatusValid &&
                allTasksHaveWorkers &&
                stillInSettledPeriod &&
                fastForwarding
        );
    }

    // Conditions for going to Gate 🪿ported
    function toGateConditions(uint256 _projectID) public view returns (bool, bool) {
        ProjectManager.Project memory project = Istacam(standardCampaignAddress).getProject(_projectID);

        // Normal to gate conditions
        bool currentStatusValid = project.status ==
            ProjectManager.ProjectStatus.Stage;
        bool inGatePeriod = block.timestamp >=
            project.nextMilestone.startGateTimestamp;

        // For fast forward to gate conditions
        bool fastForwarding = false; // checkFastForwardStatus(_projectID);
        bool stillInStagePeriod = block.timestamp <
            project.nextMilestone.startGateTimestamp;
        bool allTasksHaveSubmissions = true;

        if (fastForwarding) {
            for (uint256 i = 0; i < project.childTasks.length; i++) {
                if (
                    Istacam(standardCampaignAddress).getTask(project.childTasks[i]).submission.status ==
                    TaskManager.SubmissionStatus.None
                ) {
                    allTasksHaveSubmissions = false;
                }
            }
        }
        

        return (
            currentStatusValid && inGatePeriod,
            currentStatusValid &&
                stillInStagePeriod &&
                allTasksHaveSubmissions && fastForwarding
        );
    }

    // // Checks that voting conditions are met ✅
    // function checkFastForwardStatus(uint256 _projectID) public view returns (bool) {
    //     ProjectManager.Project memory project = Istacam(standardCampaignAddress).getProject(_projectID);

    //     // Check for each vote in the fastForward array, if at least 1 owner and 1 acceptor
    //     // and all workers voted true,
    //     // then could move to next stage/gate/settled
    //     uint256 ownerVotes = 0;
    //     uint256 workerVotes = 0;
    //     uint256 acceptorVotes = 0;

    //     for (uint256 i = 0; i < project.fastForward.length; i++) {
    //         if (
    //             checkIsProjectWorker(_projectID, project.fastForward[i].voter) &&
    //             project.fastForward[i].vote
    //         ) {
    //             workerVotes++;
    //         } else {
    //             return false;
    //         }
    //         if (
    //             checkIsCampaignOwner(project.parentCampaign, project.fastForward[i].voter) &&
    //             project.fastForward[i].vote
    //         ) {
    //             ownerVotes++;
    //         }
    //         if (
    //             checkIsCampaignAcceptor(project.parentCampaign, project.fastForward[i].voter) &&
    //             project.fastForward[i].vote
    //         ) {
    //             acceptorVotes++;
    //         }
    //     }

    //     return
    //         ownerVotes > 0 &&
    //         acceptorVotes > 0 &&
    //         workerVotes >= project.workers.length;
    // }

    // Check if address is worker of project ✅
    function checkIsProjectWorker(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        ProjectManager.Project memory project = Istacam(standardCampaignAddress).getProject(_id);
        bool isWorker = false;
        for (uint256 i = 0; i < project.workers.length; i++) {
            if (_address == project.workers[i]) {
                isWorker = true;
                break;
            }
        }
        return isWorker;
    }
    
    // Check if address is owner of campaign ✅
    function checkIsCampaignOwner(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        CampaignManager.Campaign memory campaign = Istacam(standardCampaignAddress).getCampaign(_id);
        bool isOwner = false;
        for (uint256 i = 0; i < campaign.owners.length; i++) {
            if (_address == campaign.owners[i]) {
                isOwner = true;
                break;
            }
        }
        return isOwner;
    }

    // Overloading: Check if address is acceptor of campaign ✅
    function checkIsCampaignAcceptor(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        CampaignManager.Campaign memory campaign = Istacam(standardCampaignAddress).getCampaign(_id);
        bool isAcceptor = false;
        for (uint256 i = 0; i < campaign.acceptors.length; i++) {
            if (_address == campaign.acceptors[i]) {
                isAcceptor = true;
                break;
            }
        }
        return isAcceptor;
    }

}