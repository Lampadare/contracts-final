// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";
import "./IStandardSubstrate.sol";

contract UpdateMaster {
    address public standardSubstrateAddress = address(0);

    constructor(address _standardSubstrateAddress) {
        require(
            standardSubstrateAddress == address(0),
            "standardSubstrateAddress must be set once"
        );
        standardSubstrateAddress = _standardSubstrateAddress;
    }

    // Says if a project is going to change status and to which status
    function whereToGo(
        uint256 _projectID
    ) public view returns (bool isGoing, ProjectManager.ProjectStatus goingTo) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        // We are in the Settled status -> maybe going to Stage
        if (project.status == ProjectManager.ProjectStatus.Settled) {
            if (toStageConditions(_projectID)) {
                return (true, ProjectManager.ProjectStatus.Stage);
            } else {
                return (false, project.status);
            }
        }
        // We are in the Stage status -> maybe going to Gate
        else if (project.status == ProjectManager.ProjectStatus.Stage) {
            if (toGateConditions(_projectID)) {
                return (true, ProjectManager.ProjectStatus.Gate);
            } else {
                return (false, project.status);
            }
        }
        // We are in the Gate status -> maybe going to PostSub
        else if (project.status == ProjectManager.ProjectStatus.Gate) {
            if (toPostSubConditions(_projectID)) {
                return (true, ProjectManager.ProjectStatus.PostSub);
            } else {
                return (false, project.status);
            }
        }
        // We are in the PostSub status -> maybe going to PostDisp
        else if (project.status == ProjectManager.ProjectStatus.PostSub) {
            if (toPostDispConditions(_projectID)) {
                return (true, ProjectManager.ProjectStatus.PostDisp);
            } else {
                return (false, project.status);
            }
        }
        // We are in the PostDisp status -> maybe going to Settled
        else {
            return (false, project.status);
        }
    }

    // TASK ID ARRAY GETTERS ///////////
    // Get the array of IDs of pending tasks that should be closed
    function getPendingTasksIDs(
        uint256 _projectID
    ) public view returns (uint256[] memory) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        uint256[] memory pendingTasks = new uint256[](
            project.childTasks.length
        );

        for (uint256 i = 0; i < project.childTasks.length; i++) {
            TaskManager.Task memory task = IStandardSubstrate(
                standardSubstrateAddress
            ).getTask(project.childTasks[i]);

            if (task.submissionStatus == TaskManager.SubmissionStatus.Pending) {
                pendingTasks[i] = task.id;
            } else {
                pendingTasks[i] = 0;
            }
        }

        return pendingTasks;
    }

    // Get the array of IDs of declined tasks that should be closed
    function getDeclinedTasksIDs(
        uint256 _projectID
    ) public view returns (uint256[] memory) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        uint256[] memory declinedTasks = new uint256[](
            project.childTasks.length
        );

        for (uint256 i = 0; i < project.childTasks.length; i++) {
            TaskManager.Task memory task = IStandardSubstrate(
                standardSubstrateAddress
            ).getTask(project.childTasks[i]);

            if (
                task.submissionStatus == TaskManager.SubmissionStatus.Declined
            ) {
                declinedTasks[i] = task.id;
            } else {
                declinedTasks[i] = 0;
            }
        }

        return declinedTasks;
    }

    // Get the array of IDs of "none" tasks that should be closed
    function getNoneTasksIDs(
        uint256 _projectID
    ) public view returns (uint256[] memory) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        uint256[] memory noneTasks = new uint256[](project.childTasks.length);

        for (uint256 i = 0; i < project.childTasks.length; i++) {
            TaskManager.Task memory task = IStandardSubstrate(
                standardSubstrateAddress
            ).getTask(project.childTasks[i]);

            if (task.submissionStatus == TaskManager.SubmissionStatus.None) {
                noneTasks[i] = task.id;
            } else {
                noneTasks[i] = 0;
            }
        }

        return noneTasks;
    }

    // Get the array of IDs of "disputed" tasks that should not lose their funds
    function getDisputedTasksIDs(
        uint256 _projectID
    ) public view returns (uint256[] memory) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        uint256[] memory disputedTasks = new uint256[](
            project.childTasks.length
        );

        for (uint256 i = 0; i < project.childTasks.length; i++) {
            TaskManager.Task memory task = IStandardSubstrate(
                standardSubstrateAddress
            ).getTask(project.childTasks[i]);

            if (
                task.submissionStatus == TaskManager.SubmissionStatus.Disputed
            ) {
                disputedTasks[i] = task.id;
            } else {
                disputedTasks[i] = 0;
            }
        }

        return disputedTasks;
    }

    // PROJECT REWARDS COMPUTATION ///////////
    // Compute project rewards by going up the tree
    function computeProjectReward(
        uint256 _projectID
    ) public view returns (uint256) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        CampaignManager.Campaign memory campaign = IStandardSubstrate(
            standardSubstrateAddress
        ).getCampaign(project.parentCampaign);

        uint256 campaignBalance = CampaignManager.getEffectiveBalance(campaign);
        uint256 cumulated_weight = project.weight;
        uint256 previous_projectID = _projectID;
        uint256 next_projectID = project.parentProject;
        uint8 counter = 1;

        while (previous_projectID != next_projectID) {
            ProjectManager.Project memory nextProject = IStandardSubstrate(
                standardSubstrateAddress
            ).getProject(next_projectID);

            cumulated_weight *= nextProject.weight;

            previous_projectID = next_projectID;
            next_projectID = nextProject.parentProject;
            counter++;
        }

        return (cumulated_weight * campaignBalance) / (100 ** counter);
    }

    // STATUS CONDITIONS CHECKS ///////////
    // Conditions for going to Stage ✅
    function toStageConditions(uint256 _projectID) public view returns (bool) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        // Conditions for normal to stage
        bool currentStatusValid = project.status ==
            ProjectManager.ProjectStatus.Settled;
        bool projectHasWorkers = project.workers.length > 0;
        bool inStagePeriod = block.timestamp >=
            project.nextMilestone.startStageTimestamp;

        // All conditions must be true to go to stage
        return (currentStatusValid && projectHasWorkers && inStagePeriod);
    }

    // Conditions for going to Gate ✅
    function toGateConditions(uint256 _projectID) public view returns (bool) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        // Normal to gate conditions
        bool currentStatusValid = project.status ==
            ProjectManager.ProjectStatus.Stage;
        bool inGatePeriod = block.timestamp >=
            project.nextMilestone.startGateTimestamp;

        return (currentStatusValid && inGatePeriod);
    }

    // Conditions for going to PostSub ✅
    function toPostSubConditions(
        uint256 _projectID
    ) public view returns (bool) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        (
            uint256 minGate,
            uint256 taskSub,
            uint256 taskDisp,
            uint256 minSettled
        ) = IStandardSubstrate(standardSubstrateAddress).getDecisionTimes();

        // Normal to PostSub conditions
        bool currentStatusValid = project.status ==
            ProjectManager.ProjectStatus.Gate;
        bool inPostSubPeriod = block.timestamp >=
            project.nextMilestone.startGateTimestamp + taskSub;

        return (currentStatusValid && inPostSubPeriod);
    }

    function toPostDispConditions(
        uint256 _projectID
    ) public view returns (bool) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        (
            uint256 minGate,
            uint256 taskSub,
            uint256 taskDisp,
            uint256 minSettled
        ) = IStandardSubstrate(standardSubstrateAddress).getDecisionTimes();

        // Normal to PostDisp conditions
        bool currentStatusValid = project.status ==
            ProjectManager.ProjectStatus.PostSub;
        bool inPostDispPeriod = block.timestamp >=
            project.nextMilestone.startGateTimestamp + taskDisp;

        return (currentStatusValid && inPostDispPeriod);
    }

    // Conditions for going to Settled ✅
    function toSettledConditions(
        uint256 _projectID
    ) public view returns (bool) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        bool currentStatusValid = project.status ==
            ProjectManager.ProjectStatus.PostDisp;
        bool inSettledPeriod = block.timestamp >=
            project.nextMilestone.startSettledTimestamp;

        return currentStatusValid && inSettledPeriod;
    }

    // Conditions for going to Closed ✅
    function toClosedConditions(uint256 _projectID) public view returns (bool) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_projectID);

        bool currentStatusValid = project.status ==
            ProjectManager.ProjectStatus.PostDisp;
        bool childProjectsClosed = true;

        for (uint256 i = 0; i < project.childProjects.length; i++) {
            if (
                IStandardSubstrate(standardSubstrateAddress)
                    .getProject(project.childProjects[i])
                    .status != ProjectManager.ProjectStatus.Closed
            ) {
                childProjectsClosed = false;
                break;
            }
        }

        return currentStatusValid && childProjectsClosed;
    }

    // ROLES CHECKS ///////////
    // Check if address is worker of project ✅s
    function checkIsProjectWorker(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        ProjectManager.Project memory project = IStandardSubstrate(
            standardSubstrateAddress
        ).getProject(_id);
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
        CampaignManager.Campaign memory campaign = IStandardSubstrate(
            standardSubstrateAddress
        ).getCampaign(_id);
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
        CampaignManager.Campaign memory campaign = IStandardSubstrate(
            standardSubstrateAddress
        ).getCampaign(_id);
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
