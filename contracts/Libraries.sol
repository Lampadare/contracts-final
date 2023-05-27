// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;


library Utilities {
    // Returns maximum of two numbers ✅
    function max(uint256 a, uint256 b) external pure returns (uint) {
        return a > b ? a : b;
    }

    // Pattern for deleting stuff from uint arrays by uint256 ID ✅
    function deleteItemInUintArray(
        uint256 _ItemID,
        uint256[] storage _array
    ) external {
        uint256 i = 0;
        while (i < _array.length) {
            if (_array[i] == _ItemID) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                return;
            }
            i++;
        }
        // Throw an error if the item was not found.
        revert("Item not found");
    }

    // Pattern for deleting stuff from address arrays by address ✅
    function deleteItemInAddressArray(
        address _ItemAddress,
        address[] storage _array
    ) external {
        uint256 i = 0;
        while (i < _array.length) {
            if (_array[i] == _ItemAddress) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                return;
            }
            i++;
        }
        // Throw an error if the item was not found.
        revert("Item not found");
    }

    // Pattern for deleting stuff from payable address arrays by address ✅
    function deleteItemInPayableAddressArray(
        address payable _ItemAddress,
        address payable[] storage _array
    ) external {
        uint256 i = 0;
        while (i < _array.length) {
            if (_array[i] == _ItemAddress) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                return;
            }
            i++;
        }
        // Throw an error if the item was not found.
        revert("Item not found");
    }
}

library FundingsManager {
    struct Fundings {
        address payable funder; // The address of the individual who contributed
        uint256 funding; // The amount of tokens the user contributed
        uint256 amountUsed; // The amount of tokens that have been paid out
        uint256 amountLocked; // The amount of tokens that have been locked
        bool fullyRefunded; // A boolean storing whether or not the contribution has been fully refunded or fully used
    }

    function fundLockAmount(
        Fundings[] storage _fundings,
        uint256 _expense
    ) external {
        uint256 expenseLoader = 0;

        // Loop through all fundings
        for (uint256 i = 0; i < _fundings.length; i++) {
            // If the funding has not been fully refunded
            if (!_fundings[i].fullyRefunded) {
                // Calculate the amount of tokens that should be locked
                uint256 remainingToLock = _expense - expenseLoader;
                // Calculate the effective balance of the funding
                uint256 effectiveBalanceFunding = _fundings[i].funding -
                    _fundings[i].amountUsed -
                    _fundings[i].amountLocked;
                // If the remaining amount to lock is more than the effective balance of the funding
                // Lock the entire effective balance of the funding
                if (remainingToLock >= effectiveBalanceFunding) {
                    _fundings[i].amountLocked += effectiveBalanceFunding;
                    expenseLoader += effectiveBalanceFunding;
                }
                // If the remaining amount to lock is less than the effective balance of the funding
                // Lock the remaining amount to lock
                else {
                    _fundings[i].amountLocked += remainingToLock;
                    expenseLoader = _expense;
                    return;
                }
            }
        }
    }

    // Unlock amounts of funds by going through each funding and unlocking until the expense is covered ✅
    function fundUnlockAmount(
        Fundings[] storage _fundings,
        uint256 _expense
    ) external {
        uint256 expenseLoader = 0;

        // If the expense is to be unlocked, remove it from the amountLocked of the fundings (in reverse order)
        for (uint256 i = _fundings.length; i > 0; i--) {
            if (!_fundings[i - 1].fullyRefunded) {
                uint256 remainingToUnlock = _expense - expenseLoader;

                // Locked balance of this specific funding
                uint256 lockedFundingBalance = _fundings[i - 1].amountLocked;

                // If the locked balance of the funding is less than the expense loader, unlock the whole locked balance
                if (remainingToUnlock >= lockedFundingBalance) {
                    _fundings[i - 1].amountLocked = 0;
                    expenseLoader += lockedFundingBalance;
                } else {
                    _fundings[i - 1].amountLocked -= remainingToUnlock;
                    expenseLoader = _expense;
                    return;
                }
            }
        }
    }

    // Use amounts of funds by going through each funding and using until the expense is covered ✅
    function fundUseAmount(
        Fundings[] storage _fundings,
        uint256 _expense
    ) external {
        uint256 expenseLoader = 0;

        // If the expense is to be used, add it to the amountUsed of the fundings
        // loop over all the non fullyRefunded fundings and add a part to amountUsed which is proportional to how much the funding is
        for (uint256 i = 0; i < _fundings.length; i++) {
            if (!_fundings[i].fullyRefunded) {
                uint256 remainingToUse = _expense - expenseLoader;

                // Locked balance of this specific funding
                uint256 lockedFundingBalance = _fundings[i].amountLocked;

                // If what is remaining to be used is more than the locked funding balance, use the whole locked balance
                if (remainingToUse >= lockedFundingBalance) {
                    _fundings[i].amountUsed += lockedFundingBalance;
                    _fundings[i].amountLocked = 0;
                    _fundings[i].fullyRefunded = true;
                    expenseLoader += lockedFundingBalance;
                } else {
                    _fundings[i].amountUsed += remainingToUse;
                    _fundings[i].amountLocked -= remainingToUse;
                    expenseLoader = _expense;
                    return;
                }
            }
        }
    }
}

library CampaignManager {
    using FundingsManager for FundingsManager.Fundings;
    using FundingsManager for FundingsManager.Fundings[];

    struct Campaign {
        // Description of the campaign
        string metadata;
        //CampaignStyle style;
        // Timestamps & status
        uint256 creationTime;
        //uint256 deadline;
        CampaignStatus status;
        // Stakeholders
        address payable creator;
        address payable[] owners;
        address payable[] acceptors;
        address payable[] allTimeStakeholders;
        // Stake
        FundingsManager.Fundings stake;
        // FundingsManager.Fundings (contains funders)
        FundingsManager.Fundings[] fundings;
        // Child projects & All child projects (contains IDs)
        uint256[] directChildProjects;
        uint256[] allChildProjects;
    }

    enum CampaignStatus {
        Closed,
        Running
    }

    // Write Functions
    // Campaign Creation Function ✅
    function makeCampaign(
        Campaign storage _campaign,
        string memory _metadata,
        // CampaignStyle _style,
        address payable[] memory _owners,
        address payable[] memory _acceptors,
        uint256 _stake,
        uint256 _funding
    ) external {
        _campaign.metadata = _metadata;
        //_campaign.style = _style;
        _campaign.creationTime = block.timestamp;
        //campaign.deadline = _deadline;
        _campaign.status = CampaignStatus.Running;
        _campaign.creator = payable(msg.sender);
        _campaign.owners.push(payable(msg.sender));
        for (uint256 i = 0; i < _owners.length; i++) {
            _campaign.owners.push((_owners[i]));
            _campaign.allTimeStakeholders.push((_owners[i]));
        }
        for (uint256 i = 0; i < _acceptors.length; i++) {
            _campaign.acceptors.push((_acceptors[i]));
            _campaign.allTimeStakeholders.push((_acceptors[i]));
        }
        _campaign.allTimeStakeholders.push(payable(msg.sender));
        _campaign.stake.funder = payable(msg.sender);
        _campaign.stake.funding = _stake;
        _campaign.stake.amountUsed = 0;
        _campaign.stake.fullyRefunded = false;

        if (_funding > 0) {
            FundingsManager.Fundings memory newFunding;
            newFunding.funder = payable(msg.sender);
            newFunding.funding = _funding;
            _campaign.stake.amountUsed = 0;
            newFunding.fullyRefunded = false;
            _campaign.fundings.push(newFunding);
        }
    }

    // Update Campaign Function
    function updateCampaign(
        Campaign storage _campaign,
        string memory _metadata,
        // CampaignStyle _style,
        //uint256 _deadline,
        CampaignManager.CampaignStatus _status,
        address payable[] memory _owners,
        address payable[] memory _acceptors
    ) external {
        _campaign.metadata = _metadata; //✅
        //campaign.style = _style; //❌ (needs all private-to-open effects for transition)
        //campaign.deadline = _deadline; //⚠️ (can't be less than maximum settled time of current stage of contained projects)
        _campaign.status = _status; //⚠️ (can't be closed if there are open projects)
        _campaign.owners = _owners; //✅
        for (uint256 i = 0; i < _owners.length; i++) {
            _campaign.allTimeStakeholders.push((_owners[i]));
        }
        _campaign.acceptors = _acceptors; //✅
        for (uint256 i = 0; i < _acceptors.length; i++) {
            _campaign.allTimeStakeholders.push((_acceptors[i]));
        }
    }

    // Campaign Funding Function ✅
    function fundCampaign(
        Campaign storage _campaign,
        uint256 _funding
    ) external {
        FundingsManager.Fundings memory newFunding;
        newFunding.funder = payable(msg.sender);
        newFunding.funding = _funding;
        _campaign.stake.amountUsed = 0;
        newFunding.fullyRefunded = false;
        _campaign.fundings.push(newFunding);
        _campaign.allTimeStakeholders.push(payable(msg.sender));
    }

    // Refund all campaign fundings ✅
    function refundAllCampaignFundings(Campaign storage _campaign) external {
        for (uint256 i = 0; i < _campaign.fundings.length; i++) {
            FundingsManager.Fundings storage funding = _campaign.fundings[i];

            if (!funding.fullyRefunded) {
                uint256 availableFundsForRefund = funding.funding -
                    funding.amountUsed -
                    funding.amountLocked;
                funding.amountUsed += availableFundsForRefund;
                funding.fullyRefunded = (funding.amountUsed == funding.funding);
                payable(msg.sender).transfer(availableFundsForRefund);
            }
        }
    }

    // Refund own funding ✅
    function refundOwnFunding(
        Campaign storage _campaign,
        uint256 _fundingID
    ) external {
        FundingsManager.Fundings storage funding = _campaign.fundings[
            _fundingID
        ];

        require(!funding.fullyRefunded, "Funding must not be fully refunded");
        require(funding.funder == msg.sender, "Sender must be the funder");

        uint256 availableFundsForRefund = funding.funding -
            funding.amountUsed -
            funding.amountLocked;
        funding.amountUsed += availableFundsForRefund;
        funding.fullyRefunded = (funding.amountUsed == funding.funding);
        payable(msg.sender).transfer(availableFundsForRefund);
    }

    // Refund closed Campaign stake ✅
    function refundStake(Campaign storage _campaign) external {
        if (_campaign.status == CampaignStatus.Closed) {
            _campaign.stake.amountUsed = _campaign.stake.funding;
            _campaign.stake.fullyRefunded = true;
            _campaign.creator.transfer(_campaign.stake.funding);
        }
    }

    // Read Functions
    // Library function for calculating total funding ✅
    function getTotalFunding(
        Campaign memory _campaign
    ) external pure returns (uint256) {
        uint256 _totalFunding = 0;
        for (uint256 i = 0; i < _campaign.fundings.length; i++) {
            _totalFunding += _campaign.fundings[i].funding;
        }
        return _totalFunding;
    }

    // Library function for calculating unused balance ✅
    function getUnusedBalance(
        Campaign memory _campaign
    ) external pure returns (uint256) {
        uint256 _totalBalance = 0;
        for (uint256 i = 0; i < _campaign.fundings.length; i++) {
            if (!_campaign.fundings[i].fullyRefunded) {
                uint256 balanceOfFundingStruct = _campaign.fundings[i].funding -
                    _campaign.fundings[i].amountUsed;
                _totalBalance += balanceOfFundingStruct;
            }
        }
        return _totalBalance;
    }

    // Library function for calculating locked rewards ✅
    function getLockedRewards(
        Campaign memory _campaign
    ) external pure returns (uint256) {
        uint256 _totalLockedRewards = 0;
        for (uint256 i = 0; i < _campaign.fundings.length; i++) {
            if (!_campaign.fundings[i].fullyRefunded) {
                _totalLockedRewards += _campaign.fundings[i].amountLocked;
            }
        }
        return _totalLockedRewards;
    }

    // Library function for calculating effective balance ✅
    function getEffectiveBalance(
        Campaign memory _campaign
    ) external pure returns (uint256) {
        uint256 _effectiveBalance = 0;

        for (uint256 i = 0; i < _campaign.fundings.length; i++) {
            if (!_campaign.fundings[i].fullyRefunded) {
                _effectiveBalance +=
                    _campaign.fundings[i].funding -
                    _campaign.fundings[i].amountLocked -
                    _campaign.fundings[i].amountUsed;
            }
        }

        return _effectiveBalance;
    }

    // Checking if sender is campaign owner ✅
    function checkIsCampaignOwner(
        Campaign memory _campaign
    ) external view returns (bool) {
        for (uint256 i = 0; i < _campaign.owners.length; i++) {
            if (msg.sender == _campaign.owners[i]) {
                return true;
            }
        }
        return false;
    }

    // Checking if address is campaign owner ✅
    function checkIsCampaignOwner(
        Campaign memory _campaign,
        address _address
    ) external pure returns (bool) {
        for (uint256 i = 0; i < _campaign.owners.length; i++) {
            if (_campaign.owners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Checking if sender is campaign acceptor ✅
    function checkIsCampaignAcceptor(
        Campaign memory _campaign
    ) external view returns (bool) {
        for (uint256 i = 0; i < _campaign.acceptors.length; i++) {
            if (msg.sender == _campaign.acceptors[i]) {
                return true;
            }
        }
        return false;
    }

    // Checking if address is campaign acceptor ✅
    function checkIsCampaignAcceptor(
        Campaign memory _campaign,
        address _address
    ) external pure returns (bool) {
        for (uint256 i = 0; i < _campaign.acceptors.length; i++) {
            if (_campaign.acceptors[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Unlock campaign funds equivalent to project reward ✅
    function unlockProjectRewardPostCleanup(
        Campaign storage _campaign,
        ProjectManager.Project memory _project,
        uint256 _taskSubmissionDecisionDisputeTime
    ) external {
        require(
            block.timestamp >=
                _project.nextMilestone.startGateTimestamp +
                    _taskSubmissionDecisionDisputeTime
        );

        // Unlock the funds for the project
        FundingsManager.fundUnlockAmount(_campaign.fundings, _project.reward);
    }
}

library ProjectManager {
    struct Project {
        // Description of the project
        string metadata;
        // Contribution weight
        uint256 weight;
        uint256 reward;
        // Timestamps
        uint256 creationTime;
        NextMilestone nextMilestone;
        ProjectStatus status;
        // Workers & Applications
        bool applicationRequired;
        uint256[] applications;
        address[] workers;
        address[] pastWorkers;
        // Parent Campaign & Project (contains IDs)
        uint256 parentCampaign;
        uint256 parentProject;
        // Child Tasks & Projects (contains IDs)
        uint256[] childProjects;
        uint256[] childTasks;
    }

    struct NextMilestone {
        uint256 startStageTimestamp;
        uint256 startGateTimestamp;
        uint256 startSettledTimestamp;
    }

    struct Vote {
        address voter;
        bool vote;
    }

    struct Application {
        // Description of the application
        string metadata;
        address applicant;
        bool accepted;
        FundingsManager.Fundings enrolStake;
        // Parent Project (contains IDs)
        uint256 parentProject;
    }

    enum ProjectStatus {
        Closed,
        Stage,
        Gate,
        Settled
    }

    // Write Functions
    // Project Creation Function ✅
    function makeProject(
        Project storage _project,
        string memory _metadata,
        // uint256 _deadline,
        bool _applicationRequired,
        uint256 _parentCampaignId
    ) external {
        // Populate project
        _project.metadata = _metadata;
        _project.creationTime = block.timestamp;
        _project.status = ProjectManager.ProjectStatus.Gate;
        _project.nextMilestone = ProjectManager.NextMilestone(0, 0, 0);
        _project.applicationRequired = _applicationRequired;

        // In THIS project being created, set the parent campaign and project
        _project.parentCampaign = _parentCampaignId;

        // // Open campaigns don't require applications
        // if (parentCampaign.style == CampaignManager.CampaignStyle.Open) {
        //     project.applicationRequired = false;
        // } else {
        //     project.applicationRequired = _applicationRequired;
        // }
    }

    // Find the status project should be at based on the current time ✅
    function whatStatusProjectShouldBeAt(
        Project storage _project
    ) external view returns (ProjectStatus) {
        require(_project.status != ProjectManager.ProjectStatus.Closed, "E37");
        if (block.timestamp < _project.nextMilestone.startStageTimestamp) {
            return ProjectStatus.Settled;
        } else if (
            block.timestamp < _project.nextMilestone.startGateTimestamp
        ) {
            return ProjectStatus.Stage;
        } else if (
            block.timestamp < _project.nextMilestone.startSettledTimestamp
        ) {
            return ProjectStatus.Gate;
        } else {
            return ProjectStatus.Settled;
        }
    }

    // To Stage Conditions Function ✅
    function toStageConditionsWithNotClosedTasks(
        Project storage _project,
        TaskManager.Task[] memory _notClosedTasks
    ) external view returns (bool) {
        bool currentStatusValid = _project.status ==
            ProjectManager.ProjectStatus.Settled;
        bool projectHasWorkers = _project.workers.length > 0;
        bool allTasksHaveWorkers = true;
        bool inStagePeriod = block.timestamp >=
            _project.nextMilestone.startStageTimestamp;

        // Ensure all tasks have workers
        for (uint256 i = 0; i < _notClosedTasks.length; i++) {
            if (_notClosedTasks[i].worker == address(0)) {
                allTasksHaveWorkers = false;
                return false;
            }
        }

        // All conditions must be true to go to stage
        return
            allTasksHaveWorkers &&
            currentStatusValid &&
            projectHasWorkers &&
            inStagePeriod;
    }

    // Check is project worker by address ✅
    function checkIsProjectWorker(
        Project storage _project,
        address _worker
    ) external view returns (bool) {
        for (uint256 i = 0; i < _project.workers.length; i++) {
            if (_project.workers[i] == _worker) {
                return true;
            }
        }
        return false;
    }

    // Overloading for memory project ✅
    function checkIsProjectWorker(
        Project memory _project,
        address _worker
    ) external pure returns (bool) {
        for (uint256 i = 0; i < _project.workers.length; i++) {
            if (_project.workers[i] == _worker) {
                return true;
            }
        }
        return false;
    }

    // Check msg.sender is project worker ✅
    function checkIsProjectWorker(
        Project memory _project
    ) external view returns (bool) {
        for (uint256 i = 0; i < _project.workers.length; i++) {
            if (_project.workers[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    // Enrol to project as worker when no application is required ✅
    function workerEnrolNoApplication(
        Project storage _project,
        CampaignManager.Campaign storage _campaign,
        Application storage _application,
        uint256 _id,
        uint256 _applicationCount
    ) external {
        require(!_project.applicationRequired, "E33");

        // Creates application to deal with stake

        _application.metadata = "_";
        _application.applicant = msg.sender;
        _application.accepted = true;
        _application.enrolStake.funder = payable(msg.sender);
        _application.enrolStake.funding = msg.value;
        _application.enrolStake.amountUsed = 0;
        _application.enrolStake.fullyRefunded = false;
        _application.parentProject = _id;

        _project.applications.push(_applicationCount);

        _project.workers.push(msg.sender);
        _campaign.allTimeStakeholders.push(payable(msg.sender));
    }

    // Enrol to project as worker when application is required ✅
    function applyToProject(
        Project storage _project,
        Application storage _application,
        string memory _metadata,
        uint256 _id,
        uint256 _applicationCount
    ) external {
        require(_project.applicationRequired, "E34");

        // Creates application to deal with stake

        _application.metadata = _metadata;
        _application.applicant = msg.sender;
        _application.accepted = false;
        _application.enrolStake.funder = payable(msg.sender);
        _application.enrolStake.funding = msg.value;
        _application.enrolStake.amountUsed = 0;
        _application.enrolStake.fullyRefunded = false;
        _application.parentProject = _id;

        _project.applications.push(_applicationCount);
    }

    // Worker dropout function ✅
    function workerDropOut(
        Project storage _project,
        Application storage _application,
        uint256 applicationId
    ) external {
        // Ensure sender is a worker
        bool isSenderProjectWorker = false;
        for (uint256 i = 0; i < _project.workers.length; i++) {
            if (_project.workers[i] == msg.sender) {
                isSenderProjectWorker = true;
                break;
            }
        }

        // Ensure project status is not stage
        require(
            _project.status != ProjectManager.ProjectStatus.Stage &&
                isSenderProjectWorker,
            "E28"
        );
        // Find worker's application, ensure it was accepted and not refunded
        require(
            _application.applicant == msg.sender &&
                !_application.enrolStake.fullyRefunded &&
                _application.accepted
        );
        // Remove worker from project
        Utilities.deleteItemInAddressArray(msg.sender, _project.workers);
        // Add Worker to pastWorkers in project
        _project.pastWorkers.push(msg.sender);
        // Refund stake in application
        _application.enrolStake.amountUsed = _application.enrolStake.funding;
        _application.enrolStake.fullyRefunded = true;
        payable(msg.sender).transfer(_application.enrolStake.funding);
        Utilities.deleteItemInUintArray(applicationId, _project.applications); //-> Get rid of refunded application
    }

    // Fire worker function ✅
    function fireWorker(
        Project storage _project,
        Application storage _application,
        uint256 applicationId
    ) external {
        // Ensure sender is a worker
        bool isSenderProjectWorker = false;
        for (uint256 i = 0; i < _project.workers.length; i++) {
            if (_project.workers[i] == _application.applicant) {
                isSenderProjectWorker = true;
                break;
            }
        }

        // Ensure project status is not stage
        require(
            _project.status != ProjectManager.ProjectStatus.Stage ==
                isSenderProjectWorker,
            "E30"
        );
        // Find worker's application, ensure it was accepted and not refunded
        require(
            !_application.enrolStake.fullyRefunded && _application.accepted
        );
        // Remove worker from project
        Utilities.deleteItemInAddressArray(
            _application.applicant,
            _project.workers
        );
        // Add Worker to pastWorkers in project
        _project.pastWorkers.push(_application.applicant);
        // Refund stake in application
        _application.enrolStake.amountUsed = _application.enrolStake.funding;
        _application.enrolStake.fullyRefunded = true;
        payable(msg.sender).transfer(_application.enrolStake.funding);
        Utilities.deleteItemInUintArray(applicationId, _project.applications); //-> Get rid of refunded application
    }

    function updateProjectRewardsConditions(
        Project storage _project,
        uint256 taskSubmissionDecisionDisputeTime
    ) external view returns (bool) {
        bool atGate = _project.status == ProjectManager.ProjectStatus.Gate ||
            _project.status == ProjectManager.ProjectStatus.Closed;
        bool afterCleanup = block.timestamp >
            _project.nextMilestone.startGateTimestamp +
                taskSubmissionDecisionDisputeTime;

        // Ensure all conditions are met
        return atGate && afterCleanup;
    }
}

library TaskManager {
    struct Task {
        // Description of the task
        string metadata;
        // Contribution weight
        uint256 weight;
        uint256 reward;
        bool paid;
        // Timestamps
        uint256 creationTime;
        uint256 deadline;
        // Worker
        address payable worker;
        // Completion
        Submission submission;
        bool closed;
        // Parent Campaign & Project (contains IDs)
        uint256 parentProject;
    }

    struct Submission {
        string metadata;
        SubmissionStatus status;
    }

    enum SubmissionStatus {
        None,
        Pending,
        Accepted,
        Declined,
        Disputed
    }

    enum TaskStatusFilter {
        NotClosed,
        Closed,
        All
    }

    function cleanupTask(
        Task storage _task,
        CampaignManager.Campaign storage _campaign,
        uint256 _startGateTimestamp,
        uint256 _taskSubmissionDecisionTime,
        uint256 _taskSubmissionDecisionDisputeTime
    ) external {
        // Must be in the correct decision time window
        require(
            block.timestamp > _startGateTimestamp + _taskSubmissionDecisionTime,
            "E47"
        );
        // If the task is not closed
        if (!_task.closed) {
            // If the task received submission and the decision time window has passed
            // but the submission is still pending, accept it, close it and pay the worker
            if (_task.submission.status == SubmissionStatus.Pending) {
                _task.submission.status = SubmissionStatus.Accepted;
                _task.closed = true;
                _task.paid = true;
                _task.worker.transfer(_task.reward);
                FundingsManager.fundUseAmount(_campaign.fundings, _task.reward);
            }

            // If the task received submission, which was declined and the dispute time window
            // has passed, decline it, close it and unlock the funds
            if (
                _task.submission.status ==
                TaskManager.SubmissionStatus.Declined &&
                block.timestamp >=
                _startGateTimestamp + _taskSubmissionDecisionDisputeTime
            ) {
                _task.closed = true;
                _task.paid = false;
                FundingsManager.fundUnlockAmount(
                    _campaign.fundings,
                    _task.reward
                );
            }
        }
    }
}
