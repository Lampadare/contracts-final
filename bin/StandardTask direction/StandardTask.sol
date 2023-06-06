// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";
import "./Iupmas.sol";
import "./ICheckerMaster.sol";

contract StandardTask {
    // Mapping of task IDs to tasks, IDs are numbers starting from 0
    mapping(uint256 => TaskManager.Task) public tasks;
    uint256 public taskCount = 1;

    // CheckerMaster contract address
    address public checkerMasterAddress = address(0);

    function setCheckerMasterAddress(address _checkerMasterAddress) public {
        require(checkerMasterAddress == address(0), "E51");
        checkerMasterAddress = _checkerMasterAddress;
    }

    // Create a new task
    function makeTask(
        string memory _metadata,
        uint256 weight,
        uint256 _deadline,
        uint256 _parentProjectID
    ) public returns (uint256) {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireProjectExisting(
            _parentProjectID
        );
        ICheckerMaster(checkerMasterAddress).requireCampaignOwner(
            projects[_parentProjectID].parentCampaign,
            msg.sender
        );
        // ===========================================
        require(_deadline > block.timestamp, "E38");

        TaskManager.Task storage task = tasks[taskCount];

        task.id = taskCount;
        task.metadata = _metadata;
        task.weight = weight;
        task.creationTime = block.timestamp;
        task.deadline = _deadline;

        // Add parent project to task and vice versa
        task.parentProject = _parentProjectID;
        projects[_parentProjectID].childTasks.push(taskCount);

        taskCount++;

        return taskCount - 1;
    }

    // Submit a submission to a task ✅
    function submitSubmission(uint256 _taskID, string memory _metadata) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireTaskExisting(_taskID);
        ICheckerMaster(checkerMasterAddress).requireProjectStage(
            tasks[_taskID].parentProject
        );
        ICheckerMaster(checkerMasterAddress).requireWorkerOnTask(
            _taskID,
            msg.sender
        );
        // ===========================================

        TaskManager.Task storage task = tasks[_taskID];
        require(task.deadline > block.timestamp, "E39");

        // Create submission, if it already exists, overwrite it
        // Attach the IPFS hash for metadata
        task.submission = _metadata;
        // Submission status is pending after submission
        task.submissionStatus = TaskManager.SubmissionStatus.Pending;
    }

    // Submission decision by acceptors ✅
    function submissionDecision(uint256 _taskID, bool _accepted) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireTaskExisting(_taskID);
        ICheckerMaster(checkerMasterAddress).requireProjectGate(
            tasks[_taskID].parentProject
        );
        ICheckerMaster(checkerMasterAddress).requireCampaignAcceptor(
            projects[tasks[_taskID].parentProject].parentCampaign,
            msg.sender
        );
        // ===========================================

        TaskManager.Task storage task = tasks[_taskID];
        ProjectManager.Project storage project = projects[task.parentProject];
        CampaignManager.Campaign storage campaign = campaigns[
            project.parentCampaign
        ];

        require(
            task.submissionStatus == TaskManager.SubmissionStatus.Pending,
            "E41"
        );

        // If decision is accepted, set submission status to accepted,
        // payout worker, update locked rewards and close task
        if (_accepted) {
            // Calculate the amount to pay
            uint256 toPay = (task.weight * project.reward) / 100;
            // Set the task to accepted
            task.submissionStatus = TaskManager.SubmissionStatus.Accepted;
            // Set the task to paid
            task.paid = true;
            // Reduce the project reward by the amount to pay
            project.reward -= toPay;
            // Update the locked rewards of the campaign
            FundingsManager.fundUseAmount(campaign.fundings, toPay);
            // Pay the worker
            task.worker.transfer(toPay);
            // Delete the task from the project
            Utilities.deleteItemInUintArray(task.id, project.childTasks);
        } else {
            task.submissionStatus = TaskManager.SubmissionStatus.Declined;
        }
    }

    // Assign a worker to a task ✅
    function workerSelfAssignsTask(uint256 _taskID) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireTaskExisting(_taskID);
        ICheckerMaster(checkerMasterAddress).requireProjectSettled(
            tasks[_taskID].parentProject
        );
        ICheckerMaster(checkerMasterAddress).requireWorkerOnProject(
            tasks[_taskID].parentProject,
            msg.sender
        );
        // ===========================================

        TaskManager.Task storage task = tasks[_taskID];

        task.worker = payable(msg.sender);
    }

    // Raise a dispute on a submission ✅
    function raiseDeclinedSubmissionDispute(
        uint256 _taskID,
        string memory _metadata
    ) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireTaskExisting(_taskID);
        ICheckerMaster(checkerMasterAddress).requireWorkerOnTask(
            _taskID,
            msg.sender
        );
        // ===========================================

        TaskManager.Task storage task = tasks[_taskID];

        require(
            task.submissionStatus == TaskManager.SubmissionStatus.Declined,
            "E43"
        );

        task.submissionStatus = TaskManager.SubmissionStatus.Disputed;
        task.paid = false;

        dispute(_taskID, _metadata);
    }

    // Get task by ID ✅
    function getTask(
        uint256 _taskID
    ) public view returns (TaskManager.Task memory) {
        return tasks[_taskID];
    }
}
