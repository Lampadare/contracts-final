// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";
import "./IUpdateMaster.sol";
import "./ICheckerMaster.sol";

contract StandardSubstrate {
    /// STRUCTS DECLARATIONS
    using Utilities for uint256[];
    using Utilities for address[];
    using Utilities for address payable[];
    using FundingsManager for FundingsManager.Fundings;
    using FundingsManager for FundingsManager.Fundings[];
    using CampaignManager for CampaignManager.Campaign;
    using ProjectManager for ProjectManager.Project;
    using ProjectManager for ProjectManager.Application;
    using TaskManager for TaskManager.Task;

    /// DEVELOPER FUNCTIONS (ONLY FOR TESTING) 🧑‍💻🧑‍💻🧑‍💻🧑‍💻🧑‍💻
    address public contractMaster;
    event Dispute(uint256 _id, string _metadata, uint256 _taskReward);

    constructor() payable {
        contractMaster = payable(msg.sender);
    }

    function contractMasterDrain() public {
        require(msg.sender == contractMaster, "E45");
        payable(msg.sender).transfer(address(this).balance);
    }

    function dispute(uint256 _id, string memory _metadata) internal {
        TaskManager.Task storage task = tasks[_id];
        task.submissionStatus = TaskManager.SubmissionStatus.Disputed;
        uint256 _taskReward = ((projects[task.parentProject].reward *
            task.weight) / 100);
        emit Dispute(_id, _metadata, _taskReward);
    }

    // UpdateMaster contract address
    address public updateMasterAddress = address(0);

    function setUpdateMasterAddress(address _updateMasterAddress) public {
        require(updateMasterAddress == address(0), "E51");
        updateMasterAddress = _updateMasterAddress;
    }

    // CheckerMaster contract address
    address public checkerMasterAddress = address(0);

    function setCheckerMasterAddress(address _checkerMasterAddress) public {
        require(checkerMasterAddress == address(0), "E51");
        checkerMasterAddress = _checkerMasterAddress;
    }

    // Mapping of campaign IDs to campaigns, IDs are numbers starting from 0
    mapping(uint256 => CampaignManager.Campaign) public campaigns;
    uint256 public campaignCount = 1;

    // Mapping of project IDs to projects, IDs are numbers starting from 0
    mapping(uint256 => ProjectManager.Project) public projects;
    uint256 public projectCount = 1;

    // Mapping of task IDs to tasks, IDs are numbers starting from 0
    mapping(uint256 => TaskManager.Task) public tasks;
    uint256 public taskCount = 1;

    // Mapping of application IDs to applications, IDs are numbers starting from 0
    mapping(uint256 => ProjectManager.Application) public applications;
    uint256 public applicationCount;

    // Minimum stake required to create a Private campaign
    uint256 public minStake = 0.0025 ether;
    // Minimum stake required to create an Open Campaign
    uint256 public minOpenCampaignStake = 0.025 ether;
    // Minimum stake required to enroll in a Project
    uint256 public enrolStake = 0.0025 ether;

    // Minimum time to settle a project
    uint256 public minimumSettledTime = 1 days;
    // Minimum time to end to end gate a project (Sub+Disp included)
    uint256 public minimumGateTime = 2.5 days;
    // Within gate, maximum time to decide on submissions
    uint256 public taskSubmissionDecisionTime = 1 days;
    // Within gate, maximum time to dispute a submission decision (encompasses taskSubmissionDecisionTime)
    uint256 public taskSubmissionDecisionDisputeTime = 2 days;

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// MODIFIERS
    // Stake & Funding
    modifier isMoneyIntended(uint256 _money) {
        require(msg.value == _money && _money > 0, "E16");
        _;
    }
    modifier isStakeAndFundingIntended(uint256 _stake, uint256 _funding) {
        require(msg.value == _stake + _funding, "E17");
        _;
    }
    modifier isMoreThanEnrolStake(uint256 _stake) {
        require(_stake >= enrolStake, "E18");
        _;
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// UPDATER FUNCTIONS ★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★👀★

    function new_statusFixer(uint256 _projectID) public returns (bool updated) {
        (bool isGoing, ProjectManager.ProjectStatus goingTo) = IUpdateMaster(
            updateMasterAddress
        ).whereToGo(_projectID);

        ////////////////////////////////////////////
        // If we're not going anywhere, then return
        if (!isGoing) {
            return false;
        }

        ProjectManager.Project storage project = projects[_projectID];

        ////////////////////////////////////////////
        // Settled -> Stage
        if (goingTo == ProjectManager.ProjectStatus.Stage) {
            // ✅ Adjust lateness before stage
            adjustLatenessBeforeStage(_projectID);
            // ✅ Update the project status and return updated = true
            project.status = ProjectManager.ProjectStatus.Stage;
            return true;
        }
        ////////////////////////////////////////////
        // Stage -> Gate
        else if (goingTo == ProjectManager.ProjectStatus.Gate) {
            // ✅  Delete tasks with no submissions
            // Get tasks with no submissions
            uint256[] memory noneTasksInProject = IUpdateMaster(
                updateMasterAddress
            ).getNoneTasksIDs(_projectID);
            for (uint256 i = 0; i < noneTasksInProject.length; i++) {
                // Only do the tasks that are not 0
                if (noneTasksInProject[i] == 0) {
                    continue;
                }
                // Delete the tasks
                Utilities.deleteItemInUintArray(
                    noneTasksInProject[i],
                    project.childTasks
                );
            }
            // ✅ Update the project status and return updated = true
            project.status = ProjectManager.ProjectStatus.Gate;
            return true;
        }
        ////////////////////////////////////////////
        // Gate -> PostSub
        else if (goingTo == ProjectManager.ProjectStatus.PostSub) {
            // ✅ Pending tasks are paid, marked as such and deleted
            // Get the pending tasks
            uint256[] memory pendingTaskIDsInProject = IUpdateMaster(
                updateMasterAddress
            ).getPendingTasksIDs(_projectID);
            CampaignManager.Campaign storage campaign = campaigns[
                project.parentCampaign
            ];
            // Pay the pending tasks, mark them as paid and delete them
            for (uint256 i = 0; i < pendingTaskIDsInProject.length; i++) {
                // Only do the tasks that are not 0
                if (pendingTaskIDsInProject[i] == 0) {
                    continue;
                }
                TaskManager.Task storage task = tasks[
                    pendingTaskIDsInProject[i]
                ];
                uint256 toPay = ((project.reward * task.weight) / 100);
                // Mark the task as paid
                task.paid = true;
                // Remove from project reward and campaign locked
                project.reward -= toPay;
                FundingsManager.fundUseAmount(campaign.fundings, toPay);
                // Pay the task
                task.worker.transfer(toPay);
                // Delete the taskss
                Utilities.deleteItemInUintArray(
                    pendingTaskIDsInProject[i],
                    project.childTasks
                );
            }
            // ✅ Declined tasks aren't touched
            // ✅ Update the project status and return updated = true
            project.status = ProjectManager.ProjectStatus.PostSub;
            return true;
        }
        ////////////////////////////////////////////
        // PostSub -> PostDisp
        else if (goingTo == ProjectManager.ProjectStatus.PostDisp) {
            // ✅ Get the declined tasks in the project
            uint256[] memory declinedTaskIDsInProject = IUpdateMaster(
                updateMasterAddress
            ).getDeclinedTasksIDs(_projectID);
            // ✅ Declined tasks are deleted
            for (uint256 i = 0; i < declinedTaskIDsInProject.length; i++) {
                // Only do the tasks that are not 0
                if (declinedTaskIDsInProject[i] == 0) {
                    continue;
                }
                Utilities.deleteItemInUintArray(
                    declinedTaskIDsInProject[i],
                    project.childTasks
                );
            }
            // ✅ Disputed tasks are not touched -> they are still disputed, funds are still locked
            uint256[] memory disputedTaskIDsInProject = IUpdateMaster(
                updateMasterAddress
            ).getDisputedTasksIDs(_projectID);
            // ✅ Get the disputed tasks in the project
            for (uint256 i = 0; i < disputedTaskIDsInProject.length; i++) {
                // Only do the tasks that are not 0
                if (disputedTaskIDsInProject[i] == 0) {
                    continue;
                }
                // Compute the reward for the task
                uint256 _taskReward = ((project.reward *
                    tasks[disputedTaskIDsInProject[i]].weight) / 100);
                // Remove the disputed task's reward value from project reward
                // This makes it "spent" without spending, thus ensuring it is always there
                project.reward -= _taskReward;
            }
            // ✅ Unspent money is unlocked
            CampaignManager.Campaign storage campaign = campaigns[
                project.parentCampaign
            ];
            // Unlock the funds
            campaign.fundings.fundUnlockAmount(project.reward);
            // ✅ Rewards are updated for the project (not locked yet just for informative purposes)
            project.reward = IUpdateMaster(updateMasterAddress)
                .computeProjectReward(_projectID);
            // Update the project status and return updated = true
            project.status = ProjectManager.ProjectStatus.PostDisp;
            return true;
        }
    }

    // Adjust lateness of Project before stage ✅
    function adjustLatenessBeforeStage(uint256 _projectID) internal {
        ProjectManager.Project storage project = projects[_projectID];
        uint256 lateness = 0;

        // If we are late to start stage by more than 15 minutes, add lateness to all tasks and nextmilestone
        if (
            block.timestamp >
            project.nextMilestone.startStageTimestamp + 15 minutes
        ) {
            lateness =
                block.timestamp -
                project.nextMilestone.startStageTimestamp;

            // Add lateness to all tasks
            for (uint256 i = 0; i < project.childTasks.length; i++) {
                TaskManager.Task storage task = tasks[project.childTasks[i]];
                // Ensure we only update the open tasks which also have workers in for the stage
                if (
                    task.submissionStatus !=
                    TaskManager.SubmissionStatus.Disputed &&
                    task.worker != address(0)
                ) {
                    task.deadline += lateness; // add lateness to deadline
                }
            }

            // add lateness to nextmilestone
            project.nextMilestone.startGateTimestamp += lateness;
            project.nextMilestone.startSettledTimestamp += lateness;
        }
    }

    // Close project ✅
    function closeProject(uint256 _projectID) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireProjectExisting(_projectID);
        ICheckerMaster(checkerMasterAddress).requireCampaignOwner(
            projects[_projectID].parentCampaign,
            msg.sender
        );
        // ===========================================
        // Project must fulfill the closed conditions
        require(
            IUpdateMaster(updateMasterAddress).toClosedConditions(_projectID),
            "E24"
        );
        // Update state
        projects[_projectID].status = ProjectManager.ProjectStatus.Closed;
    }

    // Go to settled ✅
    function goToSettledStatus(
        uint _projectID,
        uint256 _nextStageStartTimestamp,
        uint256 _nextGateStartTimestamp,
        uint256 _nextSettledStartTimestamp
    ) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireProjectExisting(_projectID);
        ICheckerMaster(checkerMasterAddress).requireCampaignOwner(
            projects[_projectID].parentCampaign,
            msg.sender
        );
        // ===========================================

        // Get the parent campaign and project
        CampaignManager.Campaign storage parentCampaign = campaigns[
            projects[_projectID].parentCampaign
        ];
        ProjectManager.Project storage project = projects[_projectID];

        // Check conditions for going to settled
        require(
            IUpdateMaster(updateMasterAddress).toSettledConditions(_projectID),
            "E24"
        );
        // Ensure timestamps are in order
        require(
            _nextSettledStartTimestamp > _nextGateStartTimestamp &&
                _nextGateStartTimestamp > _nextStageStartTimestamp,
            "E26"
        );

        // Get latest task deadline, for updating milestones
        uint256 latestTaskDeadline = 0;
        for (uint256 i = 0; i < project.childTasks.length; i++) {
            if (tasks[project.childTasks[i]].deadline > latestTaskDeadline) {
                latestTaskDeadline = tasks[project.childTasks[i]].deadline;
            }
        }

        // Update milestones of the project
        typicalProjectMilestonesUpdate(
            _projectID,
            _nextStageStartTimestamp,
            _nextGateStartTimestamp,
            _nextSettledStartTimestamp,
            latestTaskDeadline
        );

        // If task deadline is before timestamp of stage start or after timestamp of gate start
        //, put it to stage start. At this point, all deadlines should be between stage start and gate start
        for (uint256 i = 0; i < project.childTasks.length; i++) {
            // Clear workers of unclosed tasks when going settled
            tasks[project.childTasks[i]].worker = payable(address(0));
            // If task deadline is before timestamp of stage start and uncompleted
            if (
                tasks[project.childTasks[i]].deadline <
                project.nextMilestone.startStageTimestamp ||
                tasks[project.childTasks[i]].deadline >
                project.nextMilestone.startGateTimestamp
            ) {
                tasks[project.childTasks[i]].deadline =
                    project.nextMilestone.startGateTimestamp -
                    1 seconds;
            }
        }

        // Update project reward before locking funds
        project.reward = IUpdateMaster(updateMasterAddress)
            .computeProjectReward(_projectID);
        // Lock funds for the project
        parentCampaign.fundings.fundLockAmount(project.reward);
        // Update project status
        project.status = ProjectManager.ProjectStatus.Settled;
    }

    // Update project milestones ✅
    function typicalProjectMilestonesUpdate(
        uint256 _id,
        uint256 _nextStageStartTimestamp,
        uint256 _nextGateStartTimestamp,
        uint256 _nextSettledStartTimestamp,
        uint256 latestTaskDeadline
    ) internal {
        // Upcoming milestones based on input
        ProjectManager.NextMilestone memory _nextMilestone = ProjectManager
            .NextMilestone(
                // timestamp of stage start must be at least 24 hours from now as grace period
                Utilities.max(
                    _nextStageStartTimestamp,
                    block.timestamp + minimumSettledTime
                ),
                // timestamp of gate start is at least after latest task deadline
                Utilities.max(
                    _nextGateStartTimestamp,
                    latestTaskDeadline + 1 seconds
                ),
                // timestamp of settled start must be after latest task deadline + 2 day
                Utilities.max(
                    _nextSettledStartTimestamp,
                    Utilities.max(
                        _nextGateStartTimestamp,
                        latestTaskDeadline + 1 seconds
                    ) + minimumGateTime
                )
            );

        projects[_id].nextMilestone = _nextMilestone;
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// CAMPAIGN FUNCTIONS
    // Create a new campaign, optionally fund it ✅
    function makeCampaign(
        string memory _metadata,
        // CampaignManager.CampaignStyle _style,
        address payable[] memory _owners,
        address payable[] memory _acceptors,
        uint256 _stake,
        uint256 _funding
    )
        public
        payable
        isStakeAndFundingIntended(_stake, _funding)
        returns (uint256)
    {
        require(_stake >= minStake, "E46");
        CampaignManager.Campaign storage campaign = campaigns[campaignCount];
        campaign.makeCampaign(
            _metadata,
            // _style,
            _owners,
            _acceptors,
            _stake,
            _funding
        );

        campaignCount++;
        return campaignCount - 1;
    }

    // Update Campaign ⚠️
    function updateCampaign(
        uint256 _campaignID,
        string memory _metadata,
        // CampaignStyle _style,
        //uint256 _deadline,
        CampaignManager.CampaignStatus _status,
        address payable[] memory _owners,
        address payable[] memory _acceptors
    ) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireCampaignExisting(
            _campaignID
        );
        ICheckerMaster(checkerMasterAddress).requireCampaignOwner(
            _campaignID,
            msg.sender
        );
        // ===========================================

        require(_owners.length > 0, "E19");

        CampaignManager.Campaign storage campaign = campaigns[_campaignID];

        if (_status == CampaignManager.CampaignStatus.Closed) {
            // require that all projects inside are closed
            for (uint256 i = 0; i < campaign.directChildProjects.length; i++) {
                require(
                    projects[campaign.directChildProjects[i]].status ==
                        ProjectManager.ProjectStatus.Closed,
                    "E20"
                );
            }
            campaign.refundStake();
        }

        campaign.updateCampaign(
            _metadata,
            // _style,
            //_deadline,
            _status,
            _owners,
            _acceptors
        );
    }

    // Donate to a campaign ✅
    function fundCampaign(
        uint256 _campaignID,
        uint256 _funding
    ) public payable isMoneyIntended(_funding) {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireCampaignExisting(
            _campaignID
        );
        // ===========================================
        CampaignManager.Campaign storage campaign = campaigns[_campaignID];
        campaign.fundCampaign(_funding);
    }

    // Refund own funding ✅
    function refundOwnFunding(uint256 _campaignID, uint256 _fundingID) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireCampaignExisting(
            _campaignID
        );
        ICheckerMaster(checkerMasterAddress).requireCampaignFunder(
            _campaignID,
            msg.sender
        );
        // ===========================================
        CampaignManager.Campaign storage campaign = campaigns[_campaignID];
        campaign.refundOwnFunding(_fundingID);
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// PROJECT FUNCTIONS
    // Create a new project ✅
    function makeProject(
        string memory _metadata,
        // uint256 _deadline,
        bool _applicationRequired,
        uint256 _parentCampaignId,
        uint256 _parentProjectId,
        bool _topLevel
    ) public returns (uint256) {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireCampaignExisting(
            _parentCampaignId
        );
        ICheckerMaster(checkerMasterAddress).requireCampaignOwner(
            _parentCampaignId,
            msg.sender
        );
        // ===========================================

        require(_parentProjectId <= projectCount + 1, "E21");

        ProjectManager.Project storage project = projects[projectCount];
        CampaignManager.Campaign storage parentCampaign = campaigns[
            _parentCampaignId
        ];

        project.makeProject(
            _metadata,
            // _deadline,
            _applicationRequired,
            _parentCampaignId
        );

        // If this is a top level project, set the parent project to itself
        if (_topLevel) {
            project.parentProject = projectCount;
            // In the PARENTS of THIS project being created, add THIS project to the child projects
            // If this is a top level project, add it in the parent campaign direct child projects
            parentCampaign.directChildProjects.push(projectCount);
        } else {
            project.parentProject = _parentProjectId;
            // In the PARENTS of THIS project being created, add THIS project to the child projects
            // If this is not the top level project, add it to the parent project all child projects
            // Reference project in campaign
            projects[_parentProjectId].childProjects.push(projectCount);
        }

        projectCount++;
        return projectCount - 1;
    }

    // Worker drop out of project ✅
    function workerDropOut(uint256 _projectId, uint256 _applicationId) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireProjectExisting(_projectId);
        // ===========================================

        if (new_statusFixer(_projectId)) {
            return;
        }

        ProjectManager.Project storage project = projects[_projectId];
        ProjectManager.Application storage application = applications[
            _applicationId
        ];

        project.workerDropOut(application, _applicationId);
    }

    // Remove worker from project by owner 📍
    function fireWorker(uint256 _projectId, uint256 _applicationId) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireProjectExisting(_projectId);
        ICheckerMaster(checkerMasterAddress).requireCampaignOwner(
            projects[_projectId].parentCampaign,
            msg.sender
        );
        // ===========================================

        if (new_statusFixer(_projectId)) {
            return;
        }

        ProjectManager.Project storage project = projects[_projectId];
        ProjectManager.Application storage application = applications[
            _applicationId
        ];

        project.fireWorker(application, _applicationId);
    }

    // Enrol to project as worker when no application is required ✅
    function workerEnrolNoApplication(
        uint256 _projectID,
        uint256 _stake
    ) public payable isMoneyIntended(_stake) isMoreThanEnrolStake(_stake) {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireCampaignExisting(
            projects[_projectID].parentCampaign
        );
        ICheckerMaster(checkerMasterAddress).requireProjectExisting(_projectID);
        ICheckerMaster(checkerMasterAddress).requireCampaignRunning(
            projects[_projectID].parentCampaign
        );
        ICheckerMaster(checkerMasterAddress).requireProjectRunning(_projectID);
        // ===========================================

        if (new_statusFixer(_projectID)) {
            return;
        }

        // Get structs
        ProjectManager.Project storage project = projects[_projectID];
        CampaignManager.Campaign storage campaign = campaigns[
            project.parentCampaign
        ];
        ProjectManager.Application storage application = applications[
            applicationCount
        ];

        // Can't be a worker already
        require(!project.checkIsProjectWorker(), "E34");

        // Create application
        project.workerEnrolNoApplication(
            campaign,
            application,
            _projectID,
            applicationCount
        );

        applicationCount++;
    }

    // Apply to project to become Worker ✅
    function applyToProject(
        uint256 _projectID,
        string memory _metadata,
        uint256 _stake
    )
        public
        payable
        isMoneyIntended(_stake)
        isMoreThanEnrolStake(_stake)
        returns (uint256)
    {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireCampaignExisting(
            projects[_projectID].parentCampaign
        );
        ICheckerMaster(checkerMasterAddress).requireProjectExisting(_projectID);
        ICheckerMaster(checkerMasterAddress).requireCampaignRunning(
            projects[_projectID].parentCampaign
        );
        ICheckerMaster(checkerMasterAddress).requireProjectRunning(_projectID);
        // ===========================================

        if (new_statusFixer(_projectID)) {
            return 0;
        }

        ProjectManager.Project storage project = projects[_projectID];
        ProjectManager.Application storage application = applications[
            applicationCount
        ];

        require(!project.checkIsProjectWorker(), "E36");

        project.applyToProject(
            application,
            _metadata,
            _projectID,
            applicationCount
        );

        applicationCount++;
        return applicationCount - 1;
    }

    // Worker application decision by acceptors ✅
    function applicationDecision(
        uint256 _applicationID,
        bool _accepted
    ) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireApplicationExisting(
            _applicationID
        );
        // require campaign owner
        ICheckerMaster(checkerMasterAddress).requireCampaignOwner(
            projects[applications[_applicationID].parentProject].parentCampaign,
            msg.sender
        );
        // ===========================================

        if (new_statusFixer(applications[_applicationID].parentProject)) {
            return;
        }

        ProjectManager.Application storage application = applications[
            _applicationID
        ];
        // if project not accepted
        if (!_accepted) {
            applications[_applicationID].accepted = false;
            applications[_applicationID].enrolStake.amountUsed = application
                .enrolStake
                .funding;
            applications[_applicationID].enrolStake.fullyRefunded = true;
            Utilities.deleteItemInUintArray(
                _applicationID,
                projects[application.parentProject].applications
            );
            payable(msg.sender).transfer(
                applications[_applicationID].enrolStake.funding
            );
            return;
        } else if (_accepted) {
            projects[application.parentProject].workers.push(
                application.applicant
            );
            campaigns[projects[application.parentProject].parentCampaign]
                .allTimeStakeholders
                .push(payable(application.applicant));
            application.accepted = true;
            // deleteItemInUintArray(_applicationID, project.applications); maybe?? -> only on refund
        }
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// TASK FUNCTIONS
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

        tasks[taskCount].makeTask(
            taskCount,
            _metadata,
            weight,
            _deadline,
            _parentProjectID
        );

        // Add parent project to task and vice versa
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
        // Create submission, if it already exists, overwrite it
        // Attach the IPFS hash for metadata
        tasks[_taskID].submission = _metadata;
        // Submission status is pending after submission
        tasks[_taskID].submissionStatus = TaskManager.SubmissionStatus.Pending;
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

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    // Getter Functions

    // Get campaign by ID ✅
    function getCampaign(
        uint256 _campaignID
    ) public view returns (CampaignManager.Campaign memory) {
        return campaigns[_campaignID];
    }

    // Get projects by ID ✅
    function getProject(
        uint256 _projectID
    ) public view returns (ProjectManager.Project memory) {
        return projects[_projectID];
    }

    // Get task by ID ✅
    function getTask(
        uint256 _taskID
    ) public view returns (TaskManager.Task memory) {
        return tasks[_taskID];
    }

    // Get application by ID ✅
    function getApplication(
        uint256 _applicationID
    ) public view returns (ProjectManager.Application memory) {
        return applications[_applicationID];
    }

    // Get decision times
    function getDecisionTimes()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (
            minimumGateTime,
            taskSubmissionDecisionTime,
            taskSubmissionDecisionDisputeTime,
            minimumSettledTime
        );
    }

    receive() external payable {}

    fallback() external payable {}
}
