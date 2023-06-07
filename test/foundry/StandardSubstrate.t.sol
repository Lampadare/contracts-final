// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/StandardSubstrate.sol";
import "../../contracts/UpdateMaster.sol";
import "../../contracts/CheckerMaster.sol";
import "../../contracts/Libraries.sol";

contract standardSubstrateTest is Test {
    StandardSubstrate public standardSubstrate;
    UpdateMaster public updateMaster;
    CheckerMaster public checkerMaster;

    address payable[] public owners;
    address payable[] public acceptors;
    address payable[] public applicants;
    address payable[] public workers;
    address payable[] public funders;
    uint256 balance = 20 ether;
    uint256 numOwners = 2;
    uint256 numAcceptors = 3;
    uint256 numApplicants = 20;
    uint256 numWorkers = 10;
    uint256 numFunders = 5;

    // Create users with 100 ether balance
    function createUsers() public {
        // Make Owners
        for (uint256 i = 0; i < numOwners; i++) {
            // This will create a new address i as the private key
            address userOwner = vm.addr(i + 1);
            vm.deal(userOwner, balance);
            owners.push(payable(userOwner));
        }

        // Make Acceptors
        for (uint256 i = 0; i < numAcceptors; i++) {
            // This will create a new address i as the private key
            address userAcceptor = vm.addr(i + numOwners + 1);
            vm.deal(userAcceptor, balance);
            acceptors.push(payable(userAcceptor));
        }

        // Make Applicants
        for (uint256 i = 0; i < numApplicants; i++) {
            // This will create a new address i as the private key
            address userApplicant = vm.addr(i + numOwners + numAcceptors + 1);
            vm.deal(userApplicant, balance);
            applicants.push(payable(userApplicant));
        }

        // Make Funders
        for (uint256 i = 0; i < numFunders; i++) {
            // This will create a new address i as the private key
            address userFunder = vm.addr(
                i + numOwners + numAcceptors + numApplicants + 1
            );
            vm.deal(userFunder, balance);
            funders.push(payable(userFunder));
        }
    }

    function setUp() public {
        ////////////////////////////////////////
        // Setup Contracts
        standardSubstrate = new StandardSubstrate();
        updateMaster = new UpdateMaster(address(standardSubstrate));
        checkerMaster = new CheckerMaster(address(standardSubstrate));
        standardSubstrate.setUpdateMasterAddress(address(updateMaster));
        standardSubstrate.setCheckerMasterAddress(address(checkerMaster));

        ////////////////////////////////////////
        // Create Users
        createUsers();

        ////////////////////////////////////////
        // Create Campaign 1 for setup
        vm.prank(owners[0]);
        standardSubstrate.makeCampaign{value: 0.005 ether}(
            "test campaign 1",
            owners,
            acceptors,
            0.0025 ether,
            0.0025 ether
        );

        ////////////////////////////////////////
        // Create project 1 for setups
        // Applications are required
        bool applicationsRequired = true;
        // Assuming that a campaign has been created and its ID is 1
        uint256 parentCampaignId = 1;
        // Assuming that no parent project is applicable in this case
        uint256 parentProjectId = 0;
        // Making a top-level project
        bool topLevel = true;
        vm.prank(owners[0]);
        // Make a project
        uint256 projectId = standardSubstrate.makeProject(
            "test project 1",
            applicationsRequired,
            parentCampaignId,
            parentProjectId,
            topLevel
        );

        ////////////////////////////////////////
        // Create project 1 for setups
        vm.prank(owners[0]);
        // Make a project
        uint256 projectId_2 = standardSubstrate.makeProject(
            "test project 2",
            false, // same as 1 but applications not required
            1,
            0,
            true
        );

        ////////////////////////////////////////
        // Create 15 tasks for setup for project 1
        for (uint256 i = 0; i < 15; i++) {
            vm.prank(owners[0]);
            string memory _metadata = "test task";
            uint256 _weight = 3;
            uint256 _deadline = 1 days;
            uint256 _parentProjectID = 1;
            // Make a task
            uint256 taskId = standardSubstrate.makeTask(
                _metadata,
                _weight,
                _deadline,
                _parentProjectID
            );
        }

        ////////////////////////////////////////
        // Create 15 tasks for setup for project 2
        for (uint256 i = 0; i < 15; i++) {
            vm.prank(owners[0]);
            // Make a task
            uint256 taskId = standardSubstrate.makeTask(
                "test task",
                3,
                1 days,
                2
            );
        }
    }

    function test_makeTenCampaigns() public {
        vm.prank(owners[0]);

        for (uint256 i = 0; i < 10; i++) {
            standardSubstrate.makeCampaign{value: (i + 1) * 0.005 ether}(
                "test campaign",
                owners,
                acceptors,
                (i + 1) * 0.0025 ether,
                (i + 1) * 0.0025 ether
            );
        }
    }

    function testFail_makeTenCampaigns() public {
        vm.prank(owners[0]);

        for (uint256 i = 0; i < 10; i++) {
            standardSubstrate.makeCampaign{value: 10 ether}(
                "test campaign",
                owners,
                acceptors,
                0.0025 ether,
                0.0025 ether
            );
        }
    }

    function test_makeTenProjects() public {
        // Project Name
        string memory projectName = "test project";
        // Applications are required
        bool applicationsRequired = true;
        // Assuming that a campaign has been created and its ID is 1
        uint256 parentCampaignId = 1;
        // Assuming that no parent project is applicable in this case
        uint256 parentProjectId = 0;
        // Making a top-level project
        bool topLevel = true;

        for (uint256 i = 0; i < 10; i++) {
            vm.prank(owners[1]);
            // Make a project
            uint256 projectId = standardSubstrate.makeProject(
                projectName,
                applicationsRequired,
                parentCampaignId,
                parentProjectId,
                topLevel
            );
        }
    }

    function testFail_makeTenProjects() public {
        // Project Name
        string memory projectName = "test project";
        // Applications are required
        bool applicationsRequired = true;
        // Assuming that a campaign has been created and its ID is 1
        uint256 parentCampaignId = 1;
        // Assuming that no parent project is applicable in this case
        uint256 parentProjectId = 0;
        // Making a top-level project
        bool topLevel = true;

        for (uint256 i = 0; i < 10; i++) {
            // Make a project
            uint256 projectId = standardSubstrate.makeProject(
                projectName,
                applicationsRequired,
                parentCampaignId,
                parentProjectId,
                topLevel
            );
        }
    }

    function test_applyToProject() public {
        // Switch between all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // Assuming that a project has been created and its ID is 1
            uint256 projectId = 1;
            // Assuming that a campaign has been created and its ID is 1
            uint256 campaignId = 1;
            // Assuming that the stake is 0.01 ether
            uint256 stake = (i + 1) * 0.01 ether;

            // Use applicant
            vm.prank(applicants[i]);
            // Apply to the project
            uint256 applicationId = standardSubstrate.applyToProject{
                value: stake
            }(projectId, "test application", stake);
        }
    }

    function testFail_applytToProject() public {
        // Switch between all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // Assuming that a project has been created and its ID is 1
            uint256 projectId = 1;
            // Assuming that a campaign has been created and its ID is 1
            uint256 campaignId = 1;
            // Assuming that the stake is 0.01 ether
            uint256 stake = 0;

            // Apply to the project
            uint256 applicationId = standardSubstrate.applyToProject{
                value: stake
            }(projectId, "test application", stake);
        }
    }

    function test_applyThenAcceptApplicant() public {
        uint256 applicationId;
        // Switch between all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // Assuming that a project has been created and its ID is 1
            uint256 projectId = 1;
            // Assuming that a campaign has been created and its ID is 1
            uint256 campaignId = 1;
            // Assuming that the stake is 0.01 ether
            uint256 stake = (i + 1) * 0.01 ether;

            // Use applicant
            vm.prank(applicants[i]);
            // Apply to the project
            applicationId = standardSubstrate.applyToProject{value: stake}(
                projectId,
                "test application",
                stake
            );

            // Use owner
            vm.prank(owners[0]);
            // Accept the applicant
            if (i % 2 == 0) {
                standardSubstrate.applicationDecision(applicationId, true);
            } else {
                standardSubstrate.applicationDecision(applicationId, false);
            }
        }
    }

    function testFail_applyThenAcceptApplicant() public {
        // Switch between all applicants and apply with each
        for (uint256 i = 0; i < numApplicants; i++) {
            // Assuming that a project has been created and its ID is 1
            uint256 projectId = 1;
            // Assuming that a campaign has been created and its ID is 1
            uint256 campaignId = 1;
            // Assuming that the stake is 0.01 ether
            uint256 stake = (i + 1) * 0.01 ether;

            // Apply to the project
            // Use applicant
            vm.prank(applicants[i]);
            uint256 applicationId = standardSubstrate.applyToProject{
                value: stake
            }(projectId, "test application", stake);

            // Try to accept the applicant with all the acceptors
            for (uint256 j = 0; j < acceptors.length; i++) {
                vm.prank(acceptors[j]);
                // Accept the applicant
                standardSubstrate.applicationDecision(applicationId, true);
            }
        }
    }

    function test_workerEnrolNoApplication() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId = 2;
        // Assuming that the stake is 0.01 ether
        uint256 stake = 0.01 ether;

        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            // Use applicant
            vm.prank(applicants[i]);
            // Worker enrol
            standardSubstrate.workerEnrolNoApplication{value: stake}(
                projectId,
                stake
            );
        }
    }

    function testFail_workerEnrolNoApplication() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId = 1;
        // Assuming that the stake is 0.01 ether
        uint256 stake = 0.01 ether;

        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            // Use applicant
            vm.prank(applicants[i]);
            // Worker enrol
            standardSubstrate.workerEnrolNoApplication{value: stake}(
                projectId,
                stake
            );
        }
    }

    function test_goToSettledStatus() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        // Use owner
        vm.prank(owners[0]);
        // Go to settled
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(owners[1]);
        // Go to settled
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );
    }

    function testFail_goToSettledStatus_one() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        // Use owner
        vm.prank(applicants[0]);
        // Go to settled
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(applicants[1]);
        // Go to settled
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );
    }

    function testFail_goToSettledStatus_two() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        // Use owner
        vm.prank(applicants[0]);
        // Go to settled
        standardSubstrate.goToSettledStatus(projectId_1, 1 weeks, 0, 1 weeks);

        // Use owner
        vm.prank(applicants[1]);
        // Go to settled
        standardSubstrate.goToSettledStatus(projectId_2, 1 weeks, 0, 1 weeks);
    }

    function test_goToSettledStatusAndWorkersPickTasks() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        ///////////////////////////////////////////////////////////
        ////// Workers enrol and apply
        // Project 1 Applications
        // all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // All applicants apply to the project
            // Use applicant
            vm.prank(applicants[i]);
            uint256 applicationId = standardSubstrate.applyToProject{
                value: (i + 1) * 0.01 ether
            }(projectId_1, "test application", (i + 1) * 0.01 ether);

            // Accept the applicant
            if (i < 7) {
                vm.prank(owners[0]);
                // Accept the applicant
                standardSubstrate.applicationDecision(applicationId, true);
                // Push the worker to the workers array
                workers.push(applicants[i]);
            } else {
                vm.prank(owners[0]);
                // Reject the applicant
                standardSubstrate.applicationDecision(applicationId, false);
            }
        }
        // Project 2 Applications
        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            if (i < 7) {
                // Use applicant
                vm.prank(applicants[i]);
                // Worker enrol
                standardSubstrate.workerEnrolNoApplication{value: 0.01 ether}(
                    projectId_2,
                    0.01 ether
                );
            }
        }

        ///////////////////////////////////////////////////////////
        //Going to settled status
        // Use owner
        vm.prank(owners[0]);
        // Go to settled in project 1
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(owners[1]);
        // Go to settled in project 2
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );

        ///////////////////////////////////////////////////////////
        // Workers pick tasks
        // for each task (20 tasks) use a different worker
        // pick tasks in project 1
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 1);
        }
        // pick tasks in project 2
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 20);
        }
    }

    function test_nowGoToStage() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        ///////////////////////////////////////////////////////////
        ////// Workers enrol and apply
        // Project 1 Applications
        // all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // All applicants apply to the project
            // Use applicant
            vm.prank(applicants[i]);
            uint256 applicationId = standardSubstrate.applyToProject{
                value: (i + 1) * 0.01 ether
            }(projectId_1, "test application", (i + 1) * 0.01 ether);

            // Accept the applicant
            if (i < 7) {
                vm.prank(owners[0]);
                // Accept the applicant
                standardSubstrate.applicationDecision(applicationId, true);
                // Push the worker to the workers array
                workers.push(applicants[i]);
            } else {
                vm.prank(owners[0]);
                // Reject the applicant
                standardSubstrate.applicationDecision(applicationId, false);
            }
        }
        // Project 2 Applications
        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            if (i < 7) {
                // Use applicant
                vm.prank(applicants[i]);
                // Worker enrol
                standardSubstrate.workerEnrolNoApplication{value: 0.01 ether}(
                    projectId_2,
                    0.01 ether
                );
            }
        }

        ///////////////////////////////////////////////////////////
        //Going to settled status
        // Use owner
        vm.prank(owners[0]);
        // Go to settled in project 1
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(owners[1]);
        // Go to settled in project 2
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );

        ///////////////////////////////////////////////////////////
        // Workers pick tasks
        // for each task (20 tasks) use a different worker
        // pick tasks in project 1
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 1);
        }
        // pick tasks in project 2
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 20);
        }

        ///////////////////////////////////////////////////////////
        // Try updating the status of both projects
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during stage
        skip(1 weeks + 1 days);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);
    }

    function test_getCampaign() public {
        standardSubstrate.getCampaign(1);

        skip(1 weeks + 1 days);

        ////////////////////////////////////////
        // Create Campaign 1 for setup
        vm.prank(owners[0]);
        standardSubstrate.makeCampaign{value: 0.005 ether}(
            "test campaign 2",
            owners,
            acceptors,
            0.0025 ether,
            0.0025 ether
        );

        standardSubstrate.getCampaign(2);

        skip(2 weeks + 1 days);

        ////////////////////////////////////////
        // Create Campaign 1 for setup
        vm.prank(owners[0]);
        standardSubstrate.makeCampaign{value: 0.005 ether}(
            "test campaign 3",
            owners,
            acceptors,
            0.0025 ether,
            0.0025 ether
        );

        standardSubstrate.getCampaign(3);
    }

    function test_workersSubmitWorkInStage() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        ///////////////////////////////////////////////////////////
        ////// Workers enrol and apply
        // Project 1 Applications
        // all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // All applicants apply to the project
            // Use applicant
            vm.prank(applicants[i]);
            uint256 applicationId = standardSubstrate.applyToProject{
                value: (i + 1) * 0.01 ether
            }(projectId_1, "test application", (i + 1) * 0.01 ether);

            // Accept the applicant
            if (i < 7) {
                vm.prank(owners[0]);
                // Accept the applicant
                standardSubstrate.applicationDecision(applicationId, true);
                // Push the worker to the workers array
                workers.push(applicants[i]);
            } else {
                vm.prank(owners[0]);
                // Reject the applicant
                standardSubstrate.applicationDecision(applicationId, false);
            }
        }
        // Project 2 Applications
        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            if (i < 7) {
                // Use applicant
                vm.prank(applicants[i]);
                // Worker enrol
                standardSubstrate.workerEnrolNoApplication{value: 0.01 ether}(
                    projectId_2,
                    0.01 ether
                );
            }
        }

        ///////////////////////////////////////////////////////////
        //Going to settled status
        // Use owner
        vm.prank(owners[0]);
        // Go to settled in project 1
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(owners[1]);
        // Go to settled in project 2
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );

        ///////////////////////////////////////////////////////////
        // Workers pick tasks
        // for each task (20 tasks) use a different worker
        // pick tasks in project 1
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 1);
        }
        // pick tasks in project 2
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 20);
        }

        ///////////////////////////////////////////////////////////
        // Try updating the status of both projects
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during stage
        skip(1 weeks + 1 days);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectStage(1);
        checkerMaster.requireProjectStage(2);
        // We are now in stage

        ///////////////////////////////////////////////////////////
        // Workers submit work
        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 1, "SUBMISSION PROJECT 1");
        }

        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 20, "SUBMISSION PROJECT 2");
        }
    }

    function test_afterSubmissionGoToGateAndProvideDecisions() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        ///////////////////////////////////////////////////////////
        ////// Workers enrol and apply
        // Project 1 Applications
        // all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // All applicants apply to the project
            // Use applicant
            vm.prank(applicants[i]);
            uint256 applicationId = standardSubstrate.applyToProject{
                value: (i + 1) * 0.01 ether
            }(projectId_1, "test application", (i + 1) * 0.01 ether);

            // Accept the applicant
            if (i < 7) {
                vm.prank(owners[0]);
                // Accept the applicant
                standardSubstrate.applicationDecision(applicationId, true);
                // Push the worker to the workers array
                workers.push(applicants[i]);
            } else {
                vm.prank(owners[0]);
                // Reject the applicant
                standardSubstrate.applicationDecision(applicationId, false);
            }
        }
        // Project 2 Applications
        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            if (i < 7) {
                // Use applicant
                vm.prank(applicants[i]);
                // Worker enrol
                standardSubstrate.workerEnrolNoApplication{value: 0.01 ether}(
                    projectId_2,
                    0.01 ether
                );
            }
        }

        ///////////////////////////////////////////////////////////
        //Going to settled status
        // Use owner
        vm.prank(owners[0]);
        // Go to settled in project 1
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(owners[1]);
        // Go to settled in project 2
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );

        ///////////////////////////////////////////////////////////
        // Workers pick tasks
        // for each task (20 tasks) use a different worker
        // pick tasks in project 1
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 1);
        }
        // pick tasks in project 2
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 20);
        }

        ///////////////////////////////////////////////////////////
        // Try updating the status of both projects
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during stage
        skip(1 weeks + 15 minutes);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectStage(1);
        checkerMaster.requireProjectStage(2);
        // We are now in stage

        ///////////////////////////////////////////////////////////
        // Workers submit work
        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 1, "SUBMISSION PROJECT 1");
        }

        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 20, "SUBMISSION PROJECT 2");
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during gate, we are 2 weeks and 15 minutes into the future
        skip(1 weeks);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectGate(1);
        checkerMaster.requireProjectGate(2);

        ///////////////////////////////////////////////////////////
        // do not decide on 1 submission in each project, accept 3 and decline 2
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 3) {
                // Use owner
                vm.prank(acceptors[0]);
                // Accept the submission
                standardSubstrate.submissionDecision(i + 1, true);
            } else {
                // Use owner
                vm.prank(acceptors[0]);
                // Reject the submission
                standardSubstrate.submissionDecision(i + 1, false);
            }
        }
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 3) {
                // Use owner
                vm.prank(acceptors[0]);
                // Accept the submission
                standardSubstrate.submissionDecision(i + 20, true);
            } else {
                // Use owner
                vm.prank(acceptors[0]);
                // Reject the submission
                standardSubstrate.submissionDecision(i + 20, false);
            }
        }
    }

    function test_goToPostSubAndDisputeSome() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        ///////////////////////////////////////////////////////////
        ////// Workers enrol and apply
        // Project 1 Applications
        // all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // All applicants apply to the project
            // Use applicant
            vm.prank(applicants[i]);
            uint256 applicationId = standardSubstrate.applyToProject{
                value: (i + 1) * 0.01 ether
            }(projectId_1, "test application", (i + 1) * 0.01 ether);

            // Accept the applicant
            if (i < 7) {
                vm.prank(owners[0]);
                // Accept the applicant
                standardSubstrate.applicationDecision(applicationId, true);
                // Push the worker to the workers array
                workers.push(applicants[i]);
            } else {
                vm.prank(owners[0]);
                // Reject the applicant
                standardSubstrate.applicationDecision(applicationId, false);
            }
        }
        // Project 2 Applications
        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            if (i < 7) {
                // Use applicant
                vm.prank(applicants[i]);
                // Worker enrol
                standardSubstrate.workerEnrolNoApplication{value: 0.01 ether}(
                    projectId_2,
                    0.01 ether
                );
            }
        }

        ///////////////////////////////////////////////////////////
        //Going to settled status
        // Use owner
        vm.prank(owners[0]);
        // Go to settled in project 1
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(owners[1]);
        // Go to settled in project 2
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );

        ///////////////////////////////////////////////////////////
        // Workers pick tasks
        // for each task (20 tasks) use a different worker
        // pick tasks in project 1
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 1);
        }
        // pick tasks in project 2
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 20);
        }

        ///////////////////////////////////////////////////////////
        // Try updating the status of both projects
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during stage
        skip(1 weeks + 15 minutes);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectStage(1);
        checkerMaster.requireProjectStage(2);
        // We are now in stage

        ///////////////////////////////////////////////////////////
        // Workers submit work
        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 1, "SUBMISSION PROJECT 1");
        }

        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 20, "SUBMISSION PROJECT 2");
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during gate, we are 2 weeks and 15 minutes into the future
        skip(1 weeks);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectGate(1);
        checkerMaster.requireProjectGate(2);

        ///////////////////////////////////////////////////////////
        // do not decide on 1 submission in each project, accept 3 and decline 2
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 3) {
                // Use owner
                vm.prank(acceptors[0]);
                // Accept the submission
                standardSubstrate.submissionDecision(i + 1, false);
            } else {
                // Use owner
                vm.prank(acceptors[0]);
                // Reject the submission
                standardSubstrate.submissionDecision(i + 1, true);
            }
        }
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 3) {
                // Use owner
                vm.prank(acceptors[0]);
                // Accept the submission
                standardSubstrate.submissionDecision(i + 20, false);
            } else {
                // Use owner
                vm.prank(acceptors[0]);
                // Reject the submission
                standardSubstrate.submissionDecision(i + 20, true);
            }
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 more day into the future to be during dispute, we are 2 weeks 1hr and 15min into the future
        skip(1 days);

        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectPostSub(projectId_1);
        checkerMaster.requireProjectPostSub(projectId_2);

        // Dispute 2/3 declined submissions in each project
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 1) {
                // Use owner
                vm.prank(workers[i]);
                // Accept the submission
                standardSubstrate.raiseDeclinedSubmissionDispute(
                    i + 1,
                    "this is unfair i did the work"
                );
            }
        }
        // Dispute 2/3 declined submissions in each project
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 1) {
                // Use owner
                vm.prank(workers[i]);
                // Accept the submission
                standardSubstrate.raiseDeclinedSubmissionDispute(
                    i + 20,
                    "this is unfair i did the work"
                );
            }
        }
    }

    function test_goToPostDisp() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        ///////////////////////////////////////////////////////////
        ////// Workers enrol and apply
        // Project 1 Applications
        // all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // All applicants apply to the project
            // Use applicant
            vm.prank(applicants[i]);
            uint256 applicationId = standardSubstrate.applyToProject{
                value: (i + 1) * 0.01 ether
            }(projectId_1, "test application", (i + 1) * 0.01 ether);

            // Accept the applicant
            if (i < 7) {
                vm.prank(owners[0]);
                // Accept the applicant
                standardSubstrate.applicationDecision(applicationId, true);
                // Push the worker to the workers array
                workers.push(applicants[i]);
            } else {
                vm.prank(owners[0]);
                // Reject the applicant
                standardSubstrate.applicationDecision(applicationId, false);
            }
        }
        // Project 2 Applications
        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            if (i < 7) {
                // Use applicant
                vm.prank(applicants[i]);
                // Worker enrol
                standardSubstrate.workerEnrolNoApplication{value: 0.01 ether}(
                    projectId_2,
                    0.01 ether
                );
            }
        }

        ///////////////////////////////////////////////////////////
        //Going to settled status
        // Use owner
        vm.prank(owners[0]);
        // Go to settled in project 1
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(owners[1]);
        // Go to settled in project 2
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );

        ///////////////////////////////////////////////////////////
        // Workers pick tasks
        // for each task (20 tasks) use a different worker
        // pick tasks in project 1
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 1);
        }
        // pick tasks in project 2
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 20);
        }

        ///////////////////////////////////////////////////////////
        // Try updating the status of both projects
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during stage
        skip(1 weeks + 15 minutes);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectStage(1);
        checkerMaster.requireProjectStage(2);
        // We are now in stage

        ///////////////////////////////////////////////////////////
        // Workers submit work
        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 1, "SUBMISSION PROJECT 1");
        }

        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 20, "SUBMISSION PROJECT 2");
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during gate, we are 2 weeks and 15 minutes into the future
        skip(1 weeks);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectGate(1);
        checkerMaster.requireProjectGate(2);

        ///////////////////////////////////////////////////////////
        // do not decide on 1 submission in each project, accept 3 and decline 2
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 3) {
                // Use owner
                vm.prank(acceptors[0]);
                // Accept the submission
                standardSubstrate.submissionDecision(i + 1, false);
            } else {
                // Use owner
                vm.prank(acceptors[0]);
                // Reject the submission
                standardSubstrate.submissionDecision(i + 1, true);
            }
        }
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 3) {
                // Use owner
                vm.prank(acceptors[0]);
                // Accept the submission
                standardSubstrate.submissionDecision(i + 20, false);
            } else {
                // Use owner
                vm.prank(acceptors[0]);
                // Reject the submission
                standardSubstrate.submissionDecision(i + 20, true);
            }
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 more day into the future to be during postsub, we are 2 weeks 1hr and 15min into the future
        skip(1 days);

        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectPostSub(projectId_1);
        checkerMaster.requireProjectPostSub(projectId_2);

        // Dispute 2/3 declined submissions in each project
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 1) {
                // Use owner
                vm.prank(workers[i]);
                // Accept the submission
                standardSubstrate.raiseDeclinedSubmissionDispute(
                    i + 1,
                    "this is unfair i did the work"
                );
            }
        }
        // Dispute 2/3 declined submissions in each project
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 1) {
                // Use owner
                vm.prank(workers[i]);
                // Accept the submission
                standardSubstrate.raiseDeclinedSubmissionDispute(
                    i + 20,
                    "this is unfair i did the work"
                );
            }
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 more day into the future to be during postdisp, we are 2 weeks 1hr and 15min into the future
        skip(3 days);

        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectPostDisp(projectId_1);
        checkerMaster.requireProjectPostDisp(projectId_2);
    }

    function test_goToClosed() public {
        // Assuming that a project has been created and its ID is 1
        uint256 projectId_1 = 1;
        // Assuming that a project has been created and its ID is 2
        uint256 projectId_2 = 2;

        // Funders fund campaign
        for (uint256 i = 0; i < funders.length; i++) {
            // Use funder
            vm.prank(funders[i]);
            // Campaign and funding
            uint256 campaign_to_fund = 1;
            uint256 funding_amount = 1 ether;
            // Fund the campaign
            standardSubstrate.fundCampaign{value: funding_amount}(
                campaign_to_fund,
                funding_amount
            );
        }

        // Funders refund some campaign money
        for (uint256 i = 0; i < funders.length; i++) {
            // Use funder
            vm.prank(funders[i]);
            // Campaign and funding
            uint256 campaign_to_refund_from = 1;
            // Fund the campaign
            standardSubstrate.refundOwnFunding(campaign_to_refund_from, i + 1);
        }

        ///////////////////////////////////////////////////////////
        ////// Workers enrol and apply
        // Project 1 Applications
        // all applicants and apply with each
        for (uint256 i = 0; i < applicants.length; i++) {
            // All applicants apply to the project
            // Use applicant
            vm.prank(applicants[i]);
            uint256 applicationId = standardSubstrate.applyToProject{
                value: (i + 1) * 0.01 ether
            }(projectId_1, "test application", (i + 1) * 0.01 ether);

            // Accept the applicant
            if (i < 7) {
                vm.prank(owners[0]);
                // Accept the applicant
                standardSubstrate.applicationDecision(applicationId, true);
                // Push the worker to the workers array
                workers.push(applicants[i]);
            } else {
                vm.prank(owners[0]);
                // Reject the applicant
                standardSubstrate.applicationDecision(applicationId, false);
            }
        }
        // Project 2 Applications
        // All applicants enrol as workers
        for (uint256 i = 0; i < applicants.length; i++) {
            if (i < 7) {
                // Use applicant
                vm.prank(applicants[i]);
                // Worker enrol
                standardSubstrate.workerEnrolNoApplication{value: 0.01 ether}(
                    projectId_2,
                    0.01 ether
                );
            }
        }

        // Funders fund campaign
        for (uint256 i = 0; i < funders.length; i++) {
            // Use funder
            vm.prank(funders[i]);
            // Campaign and funding
            uint256 campaign_to_fund = 1;
            uint256 funding_amount = 1 ether;
            // Fund the campaign
            standardSubstrate.fundCampaign{value: funding_amount}(
                campaign_to_fund,
                funding_amount
            );
        }

        ///////////////////////////////////////////////////////////
        //Going to settled status
        // Use owner
        vm.prank(owners[0]);
        // Go to settled in project 1
        standardSubstrate.goToSettledStatus(
            projectId_1,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Use owner
        vm.prank(owners[1]);
        // Go to settled in project 2
        standardSubstrate.goToSettledStatus(
            projectId_2,
            1 weeks,
            2 weeks,
            3 weeks
        );

        // Funders fund campaign
        for (uint256 i = 0; i < funders.length; i++) {
            // Use funder
            vm.prank(funders[i]);
            // Campaign and funding
            uint256 campaign_to_fund = 1;
            uint256 funding_amount = 1 ether;
            // Fund the campaign
            standardSubstrate.fundCampaign{value: funding_amount}(
                campaign_to_fund,
                funding_amount
            );
        }

        ///////////////////////////////////////////////////////////
        // Workers pick tasks
        // for each task (20 tasks) use a different worker
        // pick tasks in project 1
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 1);
        }
        // pick tasks in project 2
        for (uint256 i = 0; i < workers.length; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.workerSelfAssignsTask(i + 20);
        }

        ///////////////////////////////////////////////////////////
        // Try updating the status of both projects
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        // Funders fund campaign
        for (uint256 i = 0; i < funders.length; i++) {
            // Use funder
            vm.prank(funders[i]);
            // Campaign and funding
            uint256 campaign_to_fund = 1;
            uint256 funding_amount = 1 ether;
            // Fund the campaign
            standardSubstrate.fundCampaign{value: funding_amount}(
                campaign_to_fund,
                funding_amount
            );
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during stage
        skip(1 weeks + 15 minutes);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectStage(1);
        checkerMaster.requireProjectStage(2);
        // We are now in stage

        ///////////////////////////////////////////////////////////
        // Workers submit work
        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 1, "SUBMISSION PROJECT 1");
        }

        for (uint256 i = 0; i < workers.length - 2; i++) {
            // Use worker
            vm.prank(workers[i]);
            // Pick task
            standardSubstrate.submitSubmission(i + 20, "SUBMISSION PROJECT 2");
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 week into the future to be during gate, we are 2 weeks and 15 minutes into the future
        skip(1 weeks);
        // Try updating the status of both projects again
        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectGate(1);
        checkerMaster.requireProjectGate(2);

        // Funders fund campaign
        for (uint256 i = 0; i < funders.length; i++) {
            // Use funder
            vm.prank(funders[i]);
            // Campaign and funding
            uint256 campaign_to_fund = 1;
            uint256 funding_amount = 1 ether;
            // Fund the campaign
            standardSubstrate.fundCampaign{value: funding_amount}(
                campaign_to_fund,
                funding_amount
            );
        }

        ///////////////////////////////////////////////////////////
        // do not decide on 1 submission in each project, accept 3 and decline 2
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 3) {
                // Use owner
                vm.prank(acceptors[0]);
                // Accept the submission
                standardSubstrate.submissionDecision(i + 1, false);
            } else {
                // Use owner
                vm.prank(acceptors[0]);
                // Reject the submission
                standardSubstrate.submissionDecision(i + 1, true);
            }
        }
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 3) {
                // Use owner
                vm.prank(acceptors[0]);
                // Accept the submission
                standardSubstrate.submissionDecision(i + 20, false);
            } else {
                // Use owner
                vm.prank(acceptors[0]);
                // Reject the submission
                standardSubstrate.submissionDecision(i + 20, true);
            }
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 more day into the future to be during postsub, we are 2 weeks 1hr and 15min into the future
        skip(1 days);

        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectPostSub(projectId_1);
        checkerMaster.requireProjectPostSub(projectId_2);

        // Dispute 2/3 declined submissions in each project
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 1) {
                // Use owner
                vm.prank(workers[i]);
                // Accept the submission
                standardSubstrate.raiseDeclinedSubmissionDispute(
                    i + 1,
                    "this is unfair i did the work"
                );
            }
        }
        // Dispute 2/3 declined submissions in each project
        for (uint256 i = 0; i < workers.length - 3; i++) {
            if (i < 1) {
                // Use owner
                vm.prank(workers[i]);
                // Accept the submission
                standardSubstrate.raiseDeclinedSubmissionDispute(
                    i + 20,
                    "this is unfair i did the work"
                );
            }
        }

        // Funders fund campaign
        for (uint256 i = 0; i < funders.length; i++) {
            // Use funder
            vm.prank(funders[i]);
            // Campaign and funding
            uint256 campaign_to_fund = 1;
            uint256 funding_amount = 1 ether;
            // Fund the campaign
            standardSubstrate.fundCampaign{value: funding_amount}(
                campaign_to_fund,
                funding_amount
            );
        }

        ///////////////////////////////////////////////////////////
        // Skip 1 more day into the future to be during postdisp, we are 2 weeks 1hr and 15min into the future
        skip(3 days);

        standardSubstrate.new_statusFixer(projectId_1);
        standardSubstrate.new_statusFixer(projectId_2);

        checkerMaster.requireProjectPostDisp(projectId_1);
        checkerMaster.requireProjectPostDisp(projectId_2);

        ///////////////////////////////////////////////////////////
        // Now close projects 1 and 2
        // Use owner
        vm.prank(owners[0]);
        standardSubstrate.closeProject(projectId_1);
        vm.prank(owners[0]);
        standardSubstrate.closeProject(projectId_2);

        ///////////////////////////////////////////////////////////
        // Update the campaign
        // Use owner
        vm.prank(owners[0]);
        standardSubstrate.updateCampaign(
            1,
            "UPDATED CAMPAIGN 1",
            CampaignManager.CampaignStatus.Closed,
            owners,
            acceptors
        );

        ////////////////////////////////\\\\\\\\\\\\\\\\\\\\\
        // Create Campaign 1 for setup
        vm.prank(owners[0]);
        standardSubstrate.makeCampaign{value: 0.005 ether}(
            "test campaign 2",
            owners,
            acceptors,
            0.0025 ether,
            0.0025 ether
        );

        ////////////////////////////////////////
        // Create project 3 for setups
        // Applications are required
        bool applicationsRequired = true;
        // Assuming that a campaign has been created and its ID is 1
        uint256 parentCampaignId = 2;
        // Assuming that no parent project is applicable in this case
        uint256 parentProjectId = 0;
        // Making a top-level project
        bool topLevel = true;
        vm.prank(owners[0]);
        // Make a project
        uint256 projectId_3 = standardSubstrate.makeProject(
            "test project 3",
            applicationsRequired,
            parentCampaignId,
            parentProjectId,
            topLevel
        );

        ////////////////////////////////////////
        // Create project 4 for setups
        vm.prank(owners[0]);
        // Make a project
        uint256 projectId_4 = standardSubstrate.makeProject(
            "test project 4",
            false, // same as 1 but applications not required
            1,
            0,
            true
        );

        ////////////////////////////////////////
        // Create 15 tasks for setup for project 1
        for (uint256 i = 0; i < 15; i++) {
            vm.prank(owners[0]);
            string memory _metadata = "test task";
            uint256 _weight = 3;
            uint256 _deadline = 5 weeks;
            uint256 _parentProjectID = 3;
            // Make a task
            uint256 taskId = standardSubstrate.makeTask(
                _metadata,
                _weight,
                _deadline,
                _parentProjectID
            );
        }

        ////////////////////////////////////////
        // Create 15 tasks for setup for project 2
        for (uint256 i = 0; i < 15; i++) {
            vm.prank(owners[0]);
            // Make a task
            uint256 taskId = standardSubstrate.makeTask(
                "test task",
                3,
                5 weeks,
                4
            );
        }

        ////////////////////////////////////////
        standardSubstrate.getCampaign(1);
        standardSubstrate.getCampaign(2);

        ////////////////////////////////////////
        standardSubstrate.getProject(1);
        standardSubstrate.getProject(2);
        standardSubstrate.getProject(3);
        standardSubstrate.getProject(4);

        ////////////////////////////////////////
        // get applications 1-20
        for (uint256 i = 0; i < 20; i++) {
            standardSubstrate.getApplication(i + 1);
        }

        ////////////////////////////////////////
        // get tasks 1-30
        for (uint256 i = 0; i < 30; i++) {
            standardSubstrate.getTask(i + 1);
        }
    }
}
