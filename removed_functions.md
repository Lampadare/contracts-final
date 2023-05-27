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