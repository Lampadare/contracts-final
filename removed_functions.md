    // // Cleanup all tasks that are not closed at the right time for all projects ✅
    // function cleanUpNotClosedTasksForAllProjects(uint256 _id) internal {
    //     CampaignManager.Campaign storage campaign = campaigns[_id];
    //     for (uint256 i = 0; i < campaign.allChildProjects.length; i++) {
    //         cleanUpNotClosedTasks(campaign.allChildProjects[i]);
    //     }
    // }

    // If we are where we should be and votes allow to fast forward, try to fast forward
        // Otherwise, do nothing
        // if (
        //     projects[_id].whatStatusProjectShouldBeAt() == project.status &&
        //     checkFastForwardStatus(_id)
        // ) {
        //     updateProjectStatus(_id);
        // }

    // // Conditions for going to Stage 🪿ported
    // function toStageConditions(uint256 _id) public view returns (bool, bool) {
    //     ProjectManager.Project storage project = projects[_id];

    //     bool currentStatusValid = project.status ==
    //         ProjectManager.ProjectStatus.Settled;
    //     bool projectHasWorkers = project.workers.length > 0;
    //     bool allTasksHaveWorkers = true;
    //     bool inStagePeriod = block.timestamp >=
    //         project.nextMilestone.startStageTimestamp;

    //     // For fast forward
    //     bool stillInSettledPeriod = block.timestamp <
    //         project.nextMilestone.startStageTimestamp;

    //     // Ensure all tasks have workers
    //     for (uint256 i = 0; i < project.childTasks.length; i++) {
    //         if (tasks[project.childTasks[i]].worker == address(0)) {
    //             allTasksHaveWorkers = false;
    //             return (false, false);
    //         }
    //     }

    //     // All conditions must be true to go to stage
    //     return (
    //         currentStatusValid && projectHasWorkers && inStagePeriod,
    //         currentStatusValid &&
    //             projectHasWorkers &&
    //             stillInSettledPeriod &&
    //             checkFastForwardStatus(_id)
    //     );
    // }

    // // Conditions for going to Gate 🪿ported
    // function toGateConditions(uint256 _id) public view returns (bool, bool) {
    //     ProjectManager.Project storage project = projects[_id];
    //     bool currentStatusValid = project.status ==
    //         ProjectManager.ProjectStatus.Stage;
    //     bool inGatePeriod = block.timestamp >=
    //         project.nextMilestone.startGateTimestamp;

    //     // For fast forward
    //     bool stillInStagePeriod = block.timestamp <
    //         project.nextMilestone.startGateTimestamp;
    //     bool allTasksHaveSubmissions = true;

    //     for (uint256 i = 0; i < project.childTasks.length; i++) {
    //         if (
    //             tasks[project.childTasks[i]].submission.status ==
    //             TaskManager.SubmissionStatus.None
    //         ) {
    //             allTasksHaveSubmissions = false;
    //         }
    //     }

    //     return (
    //         currentStatusValid && inGatePeriod,
    //         currentStatusValid &&
    //             stillInStagePeriod &&
    //             allTasksHaveSubmissions &&
    //             checkFastForwardStatus(_id)
    //     );
    // }

        // // Check fast forward status
    // function checkFastForwardStatus(
    //     Project memory _project,
    //     CampaignManager.Campaign memory _campaign
    // ) external pure returns (bool) {
    //     uint256 ownerVotes = 0;
    //     uint256 workerVotes = 0;
    //     uint256 acceptorVotes = 0;
    //     bool isProjectWorker = false;

    //     // Loop through fast forward votes
    //     for (uint256 i = 0; i < _project.fastForward.length; i++) {
    //         // Check if the voter is a worker
    //         for (uint256 j = 0; j < _project.workers.length; j++) {
    //             if (_project.workers[i] == _project.fastForward[i].voter) {
    //                 isProjectWorker = true;
    //             }
    //         }
    //         // If the voter is a worker and voted yes
    //         if (isProjectWorker && _project.fastForward[i].vote) {
    //             workerVotes++;
    //         } else {
    //             return false;
    //         }
    //         if (
    //             CampaignManager.checkIsCampaignOwner(
    //                 _campaign,
    //                 _project.fastForward[i].voter
    //             ) && _project.fastForward[i].vote
    //         ) {
    //             ownerVotes++;
    //         }
    //         if (
    //             CampaignManager.checkIsCampaignAcceptor(
    //                 _campaign,
    //                 _project.fastForward[i].voter
    //             ) && _project.fastForward[i].vote
    //         ) {
    //             acceptorVotes++;
    //         }
    //     }

    //     return
    //         ownerVotes > 0 &&
    //         acceptorVotes > 0 &&
    //         _project.workers.length <= workerVotes;
    // }

    // // Adjust lateness before stage
    // function updateProjectStatus(
    //     Project storage _project,
    //     CampaignManager.Campaign storage _campaign,
    //     TaskManager.Task storage _task
    // ) external {
    //     // GOING INTO STAGE 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹
    //     if (_project.status == ProjectManager.ProjectStatus.Settled) {
    //         // Check to stage conditions
    //         bool currentStatusValid = _project.status ==
    //             ProjectManager.ProjectStatus.Settled;
    //         bool projectHasWorkers = _project.workers.length > 0;
    //         bool inStagePeriod = block.timestamp >=
    //             _project.nextMilestone.startStageTimestamp;

    //         // For fast forward
    //         bool stillInSettledPeriod = block.timestamp <
    //             _project.nextMilestone.startStageTimestamp;

    //         // All conditions must be true to go to stage
    //         bool toStage = (currentStatusValid &&
    //             projectHasWorkers &&
    //             inStagePeriod);
    //         bool toStageFastForward = (currentStatusValid &&
    //             projectHasWorkers &&
    //             stillInSettledPeriod &&
    //             ProjectManager.checkFastForwardStatus(_project, _campaign));

    //         if (toStageFastForward) {
    //             // Ensure all tasks have workers
    //             require(_task.worker != address(0), "E49");
    //             // update project status
    //             _project.status = ProjectManager.ProjectStatus.Stage;
    //             // delete all votes
    //             delete _project.fastForward;
    //             return;
    //         } else if (toStage) {
    //             // adjust lateness
    //             uint256 lateness = 0;
    //             // If we are late, add lateness to all tasks and nextmilestone
    //             if (
    //                 block.timestamp > _project.nextMilestone.startStageTimestamp
    //             ) {
    //                 lateness =
    //                     block.timestamp -
    //                     _project.nextMilestone.startStageTimestamp;
    //             }
    //             if (!_task.closed) {
    //                 _task.deadline += lateness; // add lateness to deadline
    //             }
    //             // add lateness to nextmilestone
    //             _project.nextMilestone.startGateTimestamp += lateness;
    //             _project.nextMilestone.startSettledTimestamp += lateness;
    //             // update project status
    //             _project.status = ProjectManager.ProjectStatus.Stage;
    //             // delete all votes
    //             delete _project.fastForward;
    //             return;
    //         }
    //     }
    //     // GOING INTO GATE 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹
    //     else if (_project.status == ProjectManager.ProjectStatus.Stage) {
    //         // For standard conditions
    //         bool currentStatusValid = _project.status ==
    //             ProjectManager.ProjectStatus.Stage;
    //         bool inGatePeriod = block.timestamp >=
    //             _project.nextMilestone.startGateTimestamp;

    //         // For fast forward
    //         bool stillInStagePeriod = block.timestamp <
    //             _project.nextMilestone.startGateTimestamp;

    //         // Going to gate
    //         bool toGate = (currentStatusValid && inGatePeriod);
    //         // Fast forward to gate
    //         bool toGateFastForward = (currentStatusValid &&
    //             stillInStagePeriod &&
    //             ProjectManager.checkFastForwardStatus(_project, _campaign));

    //         if (toGateFastForward) {
    //             require(
    //                 _task.submission.status !=
    //                     TaskManager.SubmissionStatus.None,
    //                 "E50"
    //             );
    //             // update project status
    //             _project.status = ProjectManager.ProjectStatus.Gate;
    //             // delete all votes
    //             delete _project.fastForward;
    //             return;
    //         } else if (toGate) {
    //             // update project status
    //             _project.status = ProjectManager.ProjectStatus.Gate;
    //             // delete all votes
    //             delete _project.fastForward;
    //             return;
    //         }
    //     }
    // }

    // Vote[] fastForward;

        // enum CampaignStyle {
    //     Private,
    //     PrivateThenOpen,
    //     Open
    // }

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

    // currentStatusValid &&
            //     allTasksHaveWorkers &&
            //     stillInSettledPeriod &&
            //     fastForwarding


    // // For fast forward to stage
        // bool fastForwarding = false; // checkFastForwardStatus(_projectID);
        // bool stillInSettledPeriod = block.timestamp <
        //     project.nextMilestone.startStageTimestamp;
        // bool allTasksHaveWorkers = true;

        // // Ensure all tasks have workers
        // if (fastForwarding) {
        //     for (uint256 i = 0; i < project.childTasks.length; i++) {
        //         // Get the task and check if it has a worker
        //         if (Istacam(standardCampaignAddress).getTask(project.childTasks[i]).worker == address(0)) {
        //             allTasksHaveWorkers = false;
        //             return (false, false);
        //         }
        //     }
        // }

    // currentStatusValid &&
            //     stillInStagePeriod &&
            //     allTasksHaveSubmissions && fastForwarding

    // // For fast forward to gate conditions
        // bool fastForwarding = false; // checkFastForwardStatus(_projectID);
        // bool stillInStagePeriod = block.timestamp <
        //     project.nextMilestone.startGateTimestamp;
        // bool allTasksHaveSubmissions = true;

        // if (fastForwarding) {
        //     for (uint256 i = 0; i < project.childTasks.length; i++) {
        //         if (
        //             Istacam(standardCampaignAddress).getTask(project.childTasks[i]).submission.status ==
        //             TaskManager.SubmissionStatus.None
        //         ) {
        //             allTasksHaveSubmissions = false;
        //         }
        //     }
        // }

    // Clear fast forward votes
        delete project.fastForward;


        // // If sender is owner, acceptor or worker, append vote to fast forward status ✅
    // function voteFastForwardStatus(uint256 _id, bool _vote) public {
    //     statusFixer(_id);
    //     require(
    //         checkIsCampaignAcceptor(projects[_id].parentCampaign) ||
    //             checkIsCampaignOwner(projects[_id].parentCampaign) ||
    //             checkIsProjectWorker(_id),
    //         "E27"
    //     );
    //     ProjectManager.Project storage project = projects[_id];

    //     bool voterFound = false;

    //     for (uint256 i = 0; i < project.fastForward.length; i++) {
    //         if (project.fastForward[i].voter == msg.sender) {
    //             project.fastForward[i].vote = _vote;
    //             voterFound = true;
    //             break;
    //         }
    //     }

    //     if (!voterFound) {
    //         project.fastForward.push(ProjectManager.Vote(msg.sender, _vote));
    //     }
    // }

        // Checks that voting conditions are met 🪿ported
    function checkFastForwardStatus(uint256 _id) public view returns (bool) {
        ProjectManager.Project storage project = projects[_id];

        // Check for each vote in the fastForward array, if at least 1 owner
        // and all workers voted true, and conditions are fulfilled,
        // then move to next stage/gate/settled
        uint256 ownerVotes = 0;
        uint256 workerVotes = 0;
        uint256 acceptorVotes = 0;

        for (uint256 i = 0; i < project.fastForward.length; i++) {
            if (
                checkIsProjectWorker(_id, project.fastForward[i].voter) &&
                project.fastForward[i].vote
            ) {
                workerVotes++;
            } else {
                return false;
            }
            if (
                checkIsCampaignOwner(_id, project.fastForward[i].voter) &&
                project.fastForward[i].vote
            ) {
                ownerVotes++;
            }
            if (
                checkIsCampaignAcceptor(_id, project.fastForward[i].voter) &&
                project.fastForward[i].vote
            ) {
                acceptorVotes++;
            }
        }

        return
            ownerVotes > 0 &&
            acceptorVotes > 0 &&
            project.workers.length <= workerVotes;
    }


                if (toStageFastForward) {
                // update project status
                project.status = ProjectManager.ProjectStatus.Stage;
                return;
                // delete all votes
                // delete project.fastForward;
            } else


    if (toGateFastForward) {
                // update project status
                project.status = ProjectManager.ProjectStatus.Gate;
                return;
                // delete all votes
                // delete project.fastForward;

            } else

    // Unlock the funds for all projects that can have their funds unlocked ✅
    function unlockTheFundsForAllProjectsPostCleanup(uint256 _id) internal {
        CampaignManager.Campaign storage campaign = campaigns[_id];
        for (uint256 i = 0; i < campaign.allChildProjects.length; i++) {
            unlockTheFundsForProjectPostCleanup(campaign.allChildProjects[i]);
        }
    }

        function unlockTheFundsForProjectPostCleanup(uint256 _id) internal {
        ProjectManager.Project storage project = projects[_id];

        // We must be past the decision time and dispute time
        if (
            block.timestamp <=
            project.nextMilestone.startGateTimestamp +
                taskSubmissionDecisionDisputeTime
        ) {
            return;
        }

        // Unlock the funds for the project
        fundUnlockAmount(project.parentCampaign, project.reward);
    }

    // Unlock amounts of funds by going through each funding and unlocking until the expense is covered ✅
    function fundUnlockAmount(uint256 _id, uint256 _expense) internal {
        checkCampaignExists(_id);
        CampaignManager.Campaign storage campaign = campaigns[_id];
        campaign.fundings.fundUnlockAmount(_expense);
    }


        // // Update project STATUS oooold
    // function updateProjectStatus(
    //     uint256 _id
    // )
    //     public
    //     isProjectRunning(_id)
    //     isCampaignRunning(projects[_id].parentCampaign)
    // {
    //     checkProjectExists(_id);
    //     ProjectManager.Project storage project = projects[_id];

    //     // GOING INTO STAGE 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹
    //     if (project.status == ProjectManager.ProjectStatus.Settled) {
    //         bool toStage = Icheckers(checkersAddress).toStageConditions(_id);
    //         if (toStage) {
    //             // adjust lateness
    //             adjustLatenessBeforeStage(_id);
    //             // update project status
    //             project.status = ProjectManager.ProjectStatus.Stage;
    //             return;
    //         }
    //     }
    //     // GOING INTO GATE 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹
    //     else if (project.status == ProjectManager.ProjectStatus.Stage) {
    //         bool toGate = Icheckers(checkersAddress).toGateConditions(_id);
    //         if (toGate) {
    //             // update project status
    //             project.status = ProjectManager.ProjectStatus.Gate;
    //             return;
    //         }
    //     }
    // }


        // Check if project can update the rewards ✅
    function updateProjectRewardsConditions(
        uint256 _id
    ) public view returns (bool) {
        ProjectManager.Project storage project = projects[_id];

        bool atGate = project.status == ProjectManager.ProjectStatus.Gate ||
            project.status == ProjectManager.ProjectStatus.Closed;
        bool afterCleanup = block.timestamp >
            project.nextMilestone.startGateTimestamp +
                taskSubmissionDecisionDisputeTime;

        // Ensure all conditions are met
        return atGate && afterCleanup;
    }


        // Compute rewards for all projects and tasks in a campaign ✅
    function computeAllRewardsInCampaign(
        uint256 _id
    ) public isCampaignRunning(_id) {
        checkCampaignExists(projects[_id].parentCampaign);
        // Get the campaign
        CampaignManager.Campaign storage campaign = campaigns[_id];

        // unlock the funds of the project -> inside check we're past decision time and dispute time

        // Loop over all direct projects in the campaign
        for (uint256 i = 0; i < campaign.directChildProjects.length; i++) {
            uint256 projectId = campaign.directChildProjects[i];

            // Compute rewards for the project and its tasks recursively
            computeProjectRewards(projectId, campaign.getEffectiveBalance());
        }
    }

    // Compute rewards for all projects and tasks in a campaign helper function ✅
    function computeProjectRewards(
        uint256 _id,
        uint256 _fundsAtThatLevel
    ) internal {
        checkProjectExists(_id);
        ProjectManager.Project storage project = projects[_id];
        uint256 thisProjectReward;

        if (project.status == ProjectManager.ProjectStatus.Closed) {
            return;
        }

        // If the project is top level project
        if (project.parentProject == _id) {
            // Compute the reward for the project at this level
            thisProjectReward = (_fundsAtThatLevel * project.weight) / 1000;
            // If the project fulfills conditions, then actually update the reward
            if (updateProjectRewardsConditions(_id)) {
                project.reward = thisProjectReward;
            }
        } else {
            // If the project is not a top level project take the reward
            // given from the parent project computation
            if (updateProjectRewardsConditions(_id)) {
                project.reward = _fundsAtThatLevel;
            }
        }

        // Updating tasks requires reward conditions to be met
        if (updateProjectRewardsConditions(_id)) {
            for (uint256 i = 0; i < project.childTasks[i]; i++) {
                TaskManager.Task storage task = tasks[project.childTasks[i]];
                // Compute the reward for each task at this level)
                // Compute the reward based on the task's weight and the total weight
                uint256 taskReward = (thisProjectReward * task.weight) / 1000;

                // Update the task reward in storage
                task.reward = taskReward;
            }
        }

        // Compute the rewards for child projects
        for (uint256 i = 0; i < project.childProjects.length; i++) {
            uint256 childProjectId = project.childProjects[i];
            ProjectManager.Project storage childProject = projects[
                childProjectId
            ];

            // If project is NOT closed, then compute rewards
            if (childProject.status != ProjectManager.ProjectStatus.Closed) {
                // Calculate rewards for the child project
                uint256 childProjectReward = (thisProjectReward *
                    childProject.weight) / 1000;
                // Compute rewards for the child project and its tasks recursively
                computeProjectRewards(childProjectId, childProjectReward);
            }
        }
    }


        // Figure out where we are and where we should be and fix is needed ✅
    function statusFixer(uint256 _id) public {
        ProjectManager.Project storage project = projects[_id];

        // If we should be in settled but are in gate, then return
        // moving to settled needs owner input so we'll just wait here
        if (
            projects[_id].whatStatusProjectShouldBeAt() ==
            ProjectManager.ProjectStatus.Settled &&
            project.status == ProjectManager.ProjectStatus.Gate
        ) {
            cleanUpNotClosedTasks(_id);
            unlockTheFundsForProjectPostCleanup(project.parentCampaign);
            computeAllRewardsInCampaign(project.parentCampaign);
            return;
        } else {
            // Iterate until we get to where we should be
            while (
                projects[_id].whatStatusProjectShouldBeAt() != project.status
            ) {
                updateProjectStatus(_id);
                if (project.status == ProjectManager.ProjectStatus.Gate) {
                    break;
                }
            }
            cleanUpNotClosedTasks(_id);
            unlockTheFundsForProjectPostCleanup(project.parentCampaign);
            computeAllRewardsInCampaign(project.parentCampaign);
        }
    }

        // Automatically accept decisions which have not received a submission and are past the decision time ✅
    // Also automatically close tasks which have received declined submissions
    // and weren't disputed within the dispute time
    function cleanUpNotClosedTasks(uint256 _projectID) internal {
        ProjectManager.Project storage project = projects[_projectID];
        CampaignManager.Campaign storage campaign = campaigns[
            project.parentCampaign
        ];

        for (uint256 i = 0; i < project.childTasks.length; i++) {
            TaskManager.Task storage task = tasks[project.childTasks[i]];
            task.cleanupTask(
                campaign,
                project.nextMilestone.startGateTimestamp,
                taskSubmissionDecisionTime,
                taskSubmissionDecisionDisputeTime
            );
        }
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

        // If the task received submission and the decision time window has passed
        // but the submission is still pending, accept it, close it and pay the worker
        if (_task.submissionStatus == SubmissionStatus.Pending) {
            _task.submissionStatus = SubmissionStatus.Accepted;
            _task.paid = true;
            _task.worker.transfer(_task.reward);
            FundingsManager.fundUseAmount(_campaign.fundings, _task.reward);
        }

        // If the task received submission, which was declined and the dispute time window
        // has passed, decline it, close it and unlock the funds
        if (
            _task.submission.status == TaskManager.SubmissionStatus.Declined &&
            block.timestamp >=
            _startGateTimestamp + _taskSubmissionDecisionDisputeTime
        ) {
            _task.closed = true;
            _task.paid = false;
            FundingsManager.fundUnlockAmount(_campaign.fundings, _task.reward);
        }
    }


    // If stake by sender is strictly superior than stake of current worker on task
        // then remove current worker from task and assign sender to task
        // if (task.worker != address(0)) {
        //     if (
        //         getApplicationByApplicant(_id, task.worker).enrolStake.funding <
        //         getApplicationByApplicant(_id, msg.sender).enrolStake.funding
        //     ) {
        //         // Remove worker from task
        //         task.worker = payable(address(0));
        //         // Assign sender to task
        //         task.worker = payable(msg.sender);
        //         return;
        //     } else {
        //         return;
        //     }
        // } else {
        // Assign sender to task
        //}


        struct Vote {
        address voter;
        bool vote;
    }


        // Refund all campaign fundings ✅
    function refundAllCampaignFundings(uint256 _campaignID) public {
        // ================= Checks ==================
        ICheckerMaster(checkerMasterAddress).requireCampaignExisting(
            _campaignID
        );
        ICheckerMaster(checkerMasterAddress).requireCampaignOwner(
            _campaignID,
            msg.sender
        );
        // ===========================================
        CampaignManager.Campaign storage campaign = campaigns[_campaignID];
        campaign.refundAllCampaignFundings();
    }
