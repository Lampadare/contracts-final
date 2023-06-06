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

    address payable public owner =
        payable(0xa3d264CA0AEd76E5083092b3E06C3b81d58ef385);
    address payable public acceptor =
        payable(0xb471941FC61ec3B58915A4A0c9bE7433ad469071);
    address payable public applicant =
        payable(0xce214670E985bb5CECdF0a6Ac32C636C633a66b3);

    function setUp() public {
        ////////////////////////////////////////
        // Setup Contracts
        standardSubstrate = new StandardSubstrate();
        updateMaster = new UpdateMaster(address(standardSubstrate));
        checkerMaster = new CheckerMaster(address(standardSubstrate));
        standardSubstrate.setUpdateMasterAddress(address(updateMaster));
        standardSubstrate.setCheckerMasterAddress(address(checkerMaster));

        ////////////////////////////////////////
        // Create Campaign 1 for setup
        hoax(owner, 99999 ether);
        address payable[] memory _owners = new address payable[](1);
        _owners[0] = owner;
        address payable[] memory _acceptors = new address payable[](1);
        _acceptors[0] = acceptor;
        standardSubstrate.makeCampaign{value: 0.005 ether}(
            "test campaign 1",
            _owners,
            _acceptors,
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

        vm.prank(owner);
        // Make a project
        uint256 projectId = standardSubstrate.makeProject(
            "test project 1",
            applicationsRequired,
            parentCampaignId,
            parentProjectId,
            topLevel
        );

        ////////////////////////////////////////
        // Create task 1 for setup
        vm.prank(owner);
        string memory _metadata = "test task 1";
        uint256 _weight = 66;
        uint256 _deadline = 99999999999999;
        uint256 _parentProjectID = 1;
        // Make a task
        uint256 taskId = standardSubstrate.makeTask(
            _metadata,
            _weight,
            _deadline,
            _parentProjectID
        );
    }

    function test_makeCampaign() public {
        hoax(owner, 99999 ether);

        address payable[] memory _owners = new address payable[](1);
        _owners[0] = owner;
        address payable[] memory _acceptors = new address payable[](1);
        _acceptors[0] = acceptor;

        standardSubstrate.makeCampaign{value: 0.005 ether}(
            "test",
            _owners,
            _acceptors,
            0.0025 ether,
            0.0025 ether
        );
    }

    function testFail_makeProject() public {
        // Applications are required
        bool applicationsRequired = true;
        // Assuming that a campaign has been created and its ID is 1
        uint256 parentCampaignId = 1;
        // Assuming that no parent project is applicable in this case
        uint256 parentProjectId = 0;
        // Making a top-level project
        bool topLevel = true;

        // Make a project
        uint256 projectId = standardSubstrate.makeProject(
            "test project",
            applicationsRequired,
            parentCampaignId,
            parentProjectId,
            topLevel
        );
    }

    function test_applyToProject() public {
        // Create a fake user and fund their account
        hoax(applicant, 10 ether);
        // Assuming that a project has been created and its ID is 1
        uint256 projectId = 1;
        // Assuming that a campaign has been created and its ID is 1
        uint256 campaignId = 1;
        // Assuming that the stake is 0.01 ether
        uint256 stake = 0.01 ether;

        // Apply to the project
        uint256 applicationId = standardSubstrate.applyToProject{value: stake}(
            projectId,
            "test application",
            stake
        );

        CampaignManager.Campaign memory campaign = standardSubstrate
            .getCampaign(campaignId);
        ProjectManager.Project memory project = standardSubstrate.getProject(
            projectId
        );
    }

    function test_applyThenAcceptApplicant() public {
        // Create a fake user and fund their account
        hoax(applicant, 10 ether);
        // Assuming that a project has been created and its ID is 1
        uint256 projectId = 1;
        // Assuming that a campaign has been created and its ID is 1
        uint256 campaignId = 1;
        // Assuming that the stake is 0.01 ether
        uint256 stake = 0.01 ether;

        // Apply to the project
        uint256 applicationId = standardSubstrate.applyToProject{value: stake}(
            projectId,
            "test application",
            stake
        );

        // Accept the applicant
        vm.prank(owner);
        standardSubstrate.applicationDecision(applicationId, true);
        (applicationId);
    }

    function testFail_applyThenAcceptApplicant() public {
        // Create a fake user and fund their account
        hoax(applicant, 10 ether);
        // Assuming that a project has been created and its ID is 1
        uint256 projectId = 1;
        // Assuming that a campaign has been created and its ID is 1
        uint256 campaignId = 1;
        // Assuming that the stake is 0.01 ether
        uint256 stake = 0.01 ether;

        // Apply to the project
        uint256 applicationId = standardSubstrate.applyToProject{value: stake}(
            projectId,
            "test application",
            stake
        );

        // Accept the applicant
        vm.prank(acceptor);
        standardSubstrate.applicationDecision(applicationId, true);
        (applicationId);
    }
}
