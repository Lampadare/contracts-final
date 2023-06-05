// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";
import "./Iupmas.sol";

contract StandardCampaign {
    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
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
    event Dispute(uint256 _id, string _metadata);

    constructor() payable {
        contractMaster = payable(msg.sender);
    }

    function contractMasterDrain() public {
        require(msg.sender == contractMaster, "E45");
        payable(msg.sender).transfer(address(this).balance);
    }

    function dispute(uint256 _id, string memory _metadata) public {
        emit Dispute(_id, _metadata);
    }

    // Checkers contract address
    address public updateMasterAddress = address(0);

    function setUpdateMasterAddress(address _updateMasterAddress) public {
        require(updateMasterAddress == address(0), "E51");
        updateMasterAddress = _updateMasterAddress;
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
    // Minimum time to gate a project
    uint256 public minimumGateTime = 2.5 days;
    // Within gate, maximum time to decide on submissions
    uint256 public taskSubmissionDecisionTime = 1 days;
    // Within stage, maximum time to dispute a submission decision (encompasses taskSubmissionDecisionTime)
    uint256 public taskSubmissionDecisionDisputeTime = 2 days;

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// MODIFIERS
    // Timestamps
    function checkCampaignExists(uint256 _id) public view {
        require(_id <= campaignCount, "E1");
    }

    function checkProjectExists(uint256 _id) public view {
        require(_id <= projectCount, "E1");
    }

    function checkTaskExists(uint256 _id) public view {
        require(_id <= taskCount, "E1");
    }

    function checkApplicationExists(uint256 _id) public view {
        require(_id <= applicationCount, "E1");
    }

    // Campaign Roles
    modifier isCampaignCreator(uint256 _id) {
        require(msg.sender == campaigns[_id].creator, "E2");
        _;
    }
    modifier isCampaignOwner(uint256 _id) {
        require(checkIsCampaignOwner(_id), "E3");
        _;
    }
    modifier isCampaignFunder(uint256 _id) {
        bool isFunder = false;
        for (uint256 i = 0; i < campaigns[_id].fundings.length; i++) {
            if (msg.sender == campaigns[_id].fundings[i].funder) {
                isFunder = true;
                break;
            }
        }
        require(isFunder, "E5");
        _;
    }
    modifier isCampaignAcceptor(uint256 _id) {
        require(checkIsCampaignAcceptor(_id), "E4");
        _;
    }

    // Campaign Statuses
    modifier isCampaignRunning(uint256 _id) {
        require(
            campaigns[_id].status == CampaignManager.CampaignStatus.Running,
            "E8"
        );
        _;
    }

    // Project Statuses
    modifier isProjectGate(uint256 _id) {
        require(
            projects[_id].status == ProjectManager.ProjectStatus.Gate,
            "E11"
        );
        _;
    }
    modifier isProjectStage(uint256 _id) {
        require(
            projects[_id].status == ProjectManager.ProjectStatus.Stage,
            "E12"
        );
        _;
    }
    modifier isProjectRunning(uint256 _id) {
        require(
            projects[_id].status != ProjectManager.ProjectStatus.Closed,
            "E13"
        );
        _;
    }

    // Task Roles
    modifier isWorkerOnTask(uint256 _id) {
        require(msg.sender == tasks[_id].worker, "E15");
        _;
    }

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
        (bool isGoing, ProjectManager.ProjectStatus goingTo) = Iupmas(
            updateMasterAddress
        ).whereToGo(_projectID);

        ////////////////////////////////////////////
        // If we're not going anywhere, then return
        if (!isGoing) {
            return false;
        }

        ////////////////////////////////////////////
        // Settled -> Stage
        if (goingTo == ProjectManager.ProjectStatus.Stage) {
            // ✅ Adjust lateness before stage
            adjustLatenessBeforeStage(_projectID);
            // ✅ Update the project status and return updated = true
            projects[_projectID].status = ProjectManager.ProjectStatus.Stage;
            return true;
        }
        ////////////////////////////////////////////
        // Stage -> Gate
        else if (goingTo == ProjectManager.ProjectStatus.Gate) {
            // ✅  Delete tasks with no submissions
            // Get tasks with no submissions
            uint256[] memory noneTasksInProject = Iupmas(updateMasterAddress)
                .getNoneTasksIDs(_projectID);
            for (uint256 i = 0; i < noneTasksInProject.length; i++) {
                // Only do the tasks that are not 0
                if (noneTasksInProject[i] == 0) {
                    continue;
                }
                // Delete the tasks
                Utilities.deleteItemInUintArray(
                    noneTasksInProject[i],
                    projects[_projectID].childTasks
                );
            }
            // ✅ Update the project status and return updated = true
            projects[_projectID].status = ProjectManager.ProjectStatus.Gate;
            return true;
        }
        ////////////////////////////////////////////
        // Gate -> PostSub
        else if (goingTo == ProjectManager.ProjectStatus.PostSub) {
            // ✅ Pending tasks are paid, marked as such and deleted
            // Get the pending tasks
            uint256[] memory pendingTaskIDsInProject = Iupmas(
                updateMasterAddress
            ).getPendingTasksIDs(_projectID);
            CampaignManager.Campaign storage campaign = campaigns[
                projects[_projectID].parentCampaign
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
                uint256 toPay = ((projects[_projectID].reward * task.weight) /
                    100);
                // Mark the task as paid
                task.paid = true;
                // Remove from project reward and campaign locked
                projects[_projectID].reward -= toPay;
                FundingsManager.fundUseAmount(campaign.fundings, toPay);
                // Pay the task
                task.worker.transfer(toPay);
                // Delete the taskss
                Utilities.deleteItemInUintArray(
                    pendingTaskIDsInProject[i],
                    projects[_projectID].childTasks
                );
            }
            // ✅ Declined tasks aren't touched
            // ✅ Update the project status and return updated = true
            projects[_projectID].status = ProjectManager.ProjectStatus.PostSub;
            return true;
        }
        ////////////////////////////////////////////
        // PostSub -> PostDisp
        else if (goingTo == ProjectManager.ProjectStatus.PostDisp) {
            // ✅ Get the declined tasks in the project
            uint256[] memory declinedTaskIDsInProject = Iupmas(
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
                    projects[_projectID].childTasks
                );
            }
            // ✅ Unspent money is unlocked
            CampaignManager.Campaign storage campaign = campaigns[
                projects[_projectID].parentCampaign
            ];
            campaign.fundings.fundUnlockAmount(projects[_projectID].reward);
            // ✅ Disputed tasks are not touched -> they are still disputed, funds are still locked
            // ✅ Rewards are updated for the project (not locked yet just for informative purposes)
            projects[_projectID].reward = Iupmas(updateMasterAddress)
                .computeProjectReward(_projectID);
            // Update the project status and return updated = true
            projects[_projectID].status = ProjectManager.ProjectStatus.PostDisp;
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
    function closeProject(uint256 _id) public {
        checkProjectExists(_id);
        // Sender must be the campaign owner
        require(checkIsCampaignOwner(projects[_id].parentCampaign), "E23");
        // Project must fulfill the closed conditions
        require(Iupmas(updateMasterAddress).toClosedConditions(_id), "E24");
        // Update state
        projects[_id].status = ProjectManager.ProjectStatus.Closed;
    }

    // Go to settled ✅
    function goToSettledStatus(
        uint _id,
        uint256 _nextStageStartTimestamp,
        uint256 _nextGateStartTimestamp,
        uint256 _nextSettledStartTimestamp
    )
        public
        isCampaignRunning(projects[_id].parentCampaign)
        isProjectRunning(_id)
    {
        checkProjectExists(_id);

        // Get the parent campaign and project
        CampaignManager.Campaign storage parentCampaign = campaigns[
            projects[_id].parentCampaign
        ];
        ProjectManager.Project storage project = projects[_id];

        // Check conditions
        // Ensure sender is an owner of the campaign
        require(checkIsCampaignOwner(project.parentCampaign), "E25");
        // Check conditions for going to settled
        require(Iupmas(updateMasterAddress).toSettledConditions(_id), "E24");
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
            _id,
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
        project.reward = Iupmas(updateMasterAddress).computeProjectReward(_id);
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
    ) private {
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
    /// CAMPAIGN WRITE FUNCTIONS 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻
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
        uint256 _id,
        string memory _metadata,
        // CampaignStyle _style,
        //uint256 _deadline,
        CampaignManager.CampaignStatus _status,
        address payable[] memory _owners,
        address payable[] memory _acceptors
    ) public isCampaignOwner(_id) {
        require(_owners.length > 0, "E19");

        CampaignManager.Campaign storage campaign = campaigns[_id];

        if (_status == CampaignManager.CampaignStatus.Closed) {
            // require that all projects inside are closed
            for (uint256 i = 0; i < campaign.allChildProjects.length; i++) {
                require(
                    projects[campaign.allChildProjects[i]].status ==
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
        uint256 _id,
        uint256 _funding
    ) public payable isMoneyIntended(_funding) {
        checkCampaignExists(_id);
        CampaignManager.Campaign storage campaign = campaigns[_id];
        campaign.fundCampaign(_funding);
    }

    // Refund all campaign fundings ✅
    function refundAllCampaignFundings(
        uint256 _id
    ) public isCampaignOwner(_id) {
        checkCampaignExists(_id);
        CampaignManager.Campaign storage campaign = campaigns[_id];
        campaign.refundAllCampaignFundings();
    }

    // Refund own funding ✅
    function refundOwnFunding(
        uint256 _id,
        uint256 _fundingID
    ) public isCampaignFunder(_id) {
        checkCampaignExists(_id);
        CampaignManager.Campaign storage campaign = campaigns[_id];
        campaign.refundOwnFunding(_fundingID);
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// PROJECT WRITE FUNCTIONS 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻
    // Create a new project ✅
    function makeProject(
        string memory _metadata,
        // uint256 _deadline,
        bool _applicationRequired,
        uint256 _parentCampaignId,
        uint256 _parentProjectId,
        bool _topLevel
    ) public returns (uint256) {
        checkCampaignExists(_parentCampaignId);
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
            projects[projectCount].parentProject = projectCount;
            // In the PARENTS of THIS project being created, add THIS project to the child projects
            // If this is a top level project, add it in the parent campaign direct child projects
            parentCampaign.directChildProjects.push(projectCount);
            parentCampaign.allChildProjects.push(projectCount);
        } else {
            projects[projectCount].parentProject = _parentProjectId;
            // In the PARENTS of THIS project being created, add THIS project to the child projects
            // If this is not the top level project, add it to the parent project all child projects
            // Reference project in campaign
            parentCampaign.allChildProjects.push(projectCount);
        }

        projectCount++;
        return projectCount - 1;
    }

    // Worker drop out of project ✅
    function workerDropOut(uint256 _projectId, uint256 _applicationId) public {
        checkProjectExists(_projectId);

        ProjectManager.Project storage project = projects[_projectId];
        ProjectManager.Application storage application = applications[
            _applicationId
        ];

        project.workerDropOut(application, _applicationId);
    }

    // Remove worker from project by owner 📍
    function fireWorker(uint256 _projectId, uint256 _applicationId) public {
        checkProjectExists(_projectId);
        require(
            checkIsCampaignOwner(projects[_projectId].parentCampaign),
            "E3"
        );

        ProjectManager.Project storage project = projects[_projectId];
        ProjectManager.Application storage application = applications[
            _applicationId
        ];

        project.fireWorker(application, _applicationId);
    }

    // Enrol to project as worker when no application is required ✅
    function workerEnrolNoApplication(
        uint256 _id,
        uint256 _stake
    )
        public
        payable
        isCampaignRunning(projects[_id].parentCampaign)
        isProjectRunning(_id)
        isMoneyIntended(_stake)
        isMoreThanEnrolStake(_stake)
    {
        checkProjectExists(_id);
        // iscampaignrunning
        // isprojectrunning
        // ismoneyintended
        // ismorethanenrolstake

        // Get structs
        ProjectManager.Project storage project = projects[_id];
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
            _id,
            applicationCount
        );

        applicationCount++;
    }

    // Apply to project to become Worker ✅
    function applyToProject(
        uint256 _projectId,
        string memory _metadata,
        uint256 _stake
    )
        public
        payable
        isCampaignRunning(projects[_projectId].parentCampaign)
        isProjectRunning(_projectId)
        isMoneyIntended(_stake)
        isMoreThanEnrolStake(_stake)
        returns (uint256)
    {
        checkCampaignExists(projects[_projectId].parentCampaign);
        checkProjectExists(_projectId);
        if (new_statusFixer(_projectId)) {
            return 0;
        }

        ProjectManager.Project storage project = projects[_projectId];
        ProjectManager.Application storage application = applications[
            applicationCount
        ];

        require(!project.checkIsProjectWorker(), "E36");

        project.applyToProject(
            application,
            _metadata,
            _projectId,
            applicationCount
        );

        applicationCount++;
        return applicationCount - 1;
    }

    // Worker application decision by acceptors ✅
    function applicationDecision(
        uint256 _applicationID,
        bool _accepted
    )
        public
        isCampaignAcceptor(
            projects[applications[_applicationID].parentProject].parentCampaign
        )
    {
        checkProjectExists(applications[_applicationID].parentProject);
        // campaignacceptor
        checkApplicationExists(_applicationID);

        ProjectManager.Application storage application = applications[
            _applicationID
        ];
        ProjectManager.Project storage project = projects[
            application.parentProject
        ];
        CampaignManager.Campaign storage campaign = campaigns[
            project.parentCampaign
        ];
        // if project or campaign is closed, decline or if project is past its deadline, decline
        // also refund stake
        if (
            project.status == ProjectManager.ProjectStatus.Closed ||
            campaigns[project.parentCampaign].status ==
            CampaignManager.CampaignStatus.Closed ||
            !_accepted
        ) {
            applications[_applicationID].accepted = false;
            applications[_applicationID].enrolStake.amountUsed = application
                .enrolStake
                .funding;
            applications[_applicationID].enrolStake.fullyRefunded = true;
            Utilities.deleteItemInUintArray(
                _applicationID,
                project.applications
            );
            payable(msg.sender).transfer(
                applications[_applicationID].enrolStake.funding
            );
            return;
        } else if (_accepted) {
            project.workers.push(application.applicant);
            campaign.allTimeStakeholders.push(payable(application.applicant));
            application.accepted = true;
            // deleteItemInUintArray(_applicationID, project.applications); maybe?? -> only on refund
        }
    }

    /// 🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳
    /// PROJECT READ FUNCTIONS 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹

    // Check if sender is owner of campaign ✅
    function checkIsCampaignOwner(uint256 _id) public view returns (bool) {
        bool isOwner = false;
        for (uint256 i = 0; i < campaigns[_id].owners.length; i++) {
            if (msg.sender == campaigns[_id].owners[i]) {
                isOwner = true;
                break;
            }
        }
        return isOwner;
    }

    // Overloading: Check if address is owner of campaign ✅ 🪿ported
    function checkIsCampaignOwner(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        bool isOwner = false;
        for (uint256 i = 0; i < campaigns[_id].owners.length; i++) {
            if (_address == campaigns[_id].owners[i]) {
                isOwner = true;
                break;
            }
        }
        return isOwner;
    }

    // Check if sender is acceptor of campaign ✅
    function checkIsCampaignAcceptor(uint256 _id) public view returns (bool) {
        bool isAcceptor = false;
        for (uint256 i = 0; i < campaigns[_id].acceptors.length; i++) {
            if (msg.sender == campaigns[_id].acceptors[i]) {
                isAcceptor = true;
                break;
            }
        }
        return isAcceptor;
    }

    // Overloading: Check if address is acceptor of campaign ✅ 🪿ported
    function checkIsCampaignAcceptor(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        bool isAcceptor = false;
        for (uint256 i = 0; i < campaigns[_id].acceptors.length; i++) {
            if (_address == campaigns[_id].acceptors[i]) {
                isAcceptor = true;
                break;
            }
        }
        return isAcceptor;
    }

    // Check if sender is worker of project ✅
    function checkIsProjectWorker(uint256 _id) public view returns (bool) {
        bool isWorker = false;
        for (uint256 i = 0; i < projects[_id].workers.length; i++) {
            if (msg.sender == projects[_id].workers[i]) {
                isWorker = true;
                break;
            }
        }
        return isWorker;
    }

    // Overloading: Check if address is worker of project ✅
    function checkIsProjectWorker(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        bool isWorker = false;
        for (uint256 i = 0; i < projects[_id].workers.length; i++) {
            if (_address == projects[_id].workers[i]) {
                isWorker = true;
                break;
            }
        }
        return isWorker;
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// TASK WRITE FUNCTIONS 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻
    // Create a new task
    function makeTask(
        string memory _metadata,
        uint256 weight,
        uint256 _deadline,
        uint256 _parentProjectID
    ) public returns (uint256) {
        checkProjectExists(_parentProjectID);
        checkCampaignExists(projects[_parentProjectID].parentCampaign);
        require(_deadline > block.timestamp, "E38");
        require(
            checkIsCampaignOwner(projects[_parentProjectID].parentCampaign),
            "E3"
        );

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
    function submitSubmission(
        uint256 _id,
        string memory _metadata
    )
        public
        isProjectRunning(tasks[_id].parentProject)
        isWorkerOnTask(_id)
        isProjectStage(tasks[_id].parentProject)
    {
        checkTaskExists(_id);
        checkProjectExists(tasks[_id].parentProject);

        TaskManager.Task storage task = tasks[_id];
        require(task.deadline > block.timestamp, "E39");

        // Create submission, if it already exists, overwrite it
        // Attach the IPFS hash for metadata
        task.submission = _metadata;
        // Submission status is pending after submission
        task.submissionStatus = TaskManager.SubmissionStatus.Pending;
    }

    // Submission decision by acceptors ✅
    function submissionDecision(
        uint256 _id,
        bool _accepted
    )
        public
        isProjectRunning(tasks[_id].parentProject)
        isCampaignAcceptor(projects[tasks[_id].parentProject].parentCampaign)
        isProjectGate(tasks[_id].parentProject)
    {
        checkTaskExists(_id);
        checkProjectExists(tasks[_id].parentProject);

        TaskManager.Task storage task = tasks[_id];
        ProjectManager.Project storage project = projects[
            tasks[_id].parentProject
        ];
        CampaignManager.Campaign storage campaign = campaigns[
            project.parentCampaign
        ];

        require(project.status == ProjectManager.ProjectStatus.Gate, "E40");
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
    function workerSelfAssignsTask(uint256 _id) public {
        checkTaskExists(_id);
        checkProjectExists(tasks[_id].parentProject);

        TaskManager.Task storage task = tasks[_id];
        ProjectManager.Project storage project = projects[task.parentProject];

        require(
            project.status == ProjectManager.ProjectStatus.Settled &&
                checkIsProjectWorker(_id),
            "E42"
        );

        task.worker = payable(msg.sender);
    }

    // Raise a dispute on a submission ✅
    function raiseDeclinedSubmissionDispute(
        uint256 _id,
        string memory _metadata
    )
        public
        isProjectRunning(tasks[_id].parentProject)
        isWorkerOnTask(_id)
        isProjectGate(tasks[_id].parentProject)
    {
        checkTaskExists(_id);
        checkProjectExists(tasks[_id].parentProject);

        TaskManager.Task storage task = tasks[_id];
        ProjectManager.Project storage project = projects[task.parentProject];

        require(
            task.submissionStatus == TaskManager.SubmissionStatus.Declined,
            "E43"
        );
        require(
            block.timestamp <
                project.nextMilestone.startGateTimestamp +
                    taskSubmissionDecisionDisputeTime,
            "E44"
        );

        task.submissionStatus = TaskManager.SubmissionStatus.Disputed;
        task.paid = false;

        dispute(_id, _metadata);
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    // Getter Functions

    // Get campaign by ID ✅
    function getCampaign(
        uint256 _id
    ) public view returns (CampaignManager.Campaign memory) {
        checkCampaignExists(_id);
        return campaigns[_id];
    }

    // Get projects by ID ✅
    function getProject(
        uint256 _id
    ) public view returns (ProjectManager.Project memory) {
        checkProjectExists(_id);
        return projects[_id];
    }

    // Get task by ID ✅
    function getTask(
        uint256 _id
    ) public view returns (TaskManager.Task memory) {
        checkTaskExists(_id);
        return tasks[_id];
    }

    // Get application by ID ✅
    function getApplication(
        uint256 _id
    ) public view returns (ProjectManager.Application memory) {
        checkApplicationExists(_id);
        return applications[_id];
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
