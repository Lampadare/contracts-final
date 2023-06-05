const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StandardCampaign", function () {
  // Contract instances
  let standardCampaign;
  let updateMaster;
  let campaignOwner;
  let user1;
  // Generate addresses
  let randomWallets = [];
  for (let i = 0; i < 10; i++) {
    let wallet = ethers.Wallet.createRandom();
    randomWallets.push(wallet);
  }
  beforeEach(async function () {
    // Libraries deployment
    const Utilities = await ethers.getContractFactory("Utilities");
    const utilities = await Utilities.deploy();
    await utilities.deployed();

    const FundingsManager = await ethers.getContractFactory("FundingsManager");
    const fundingsManager = await FundingsManager.deploy();
    await fundingsManager.deployed();

    const CampaignManager = await ethers.getContractFactory("CampaignManager", {
      libraries: {
        FundingsManager: fundingsManager.address,
      },
    });
    const campaignManager = await CampaignManager.deploy();
    await campaignManager.deployed();

    const ProjectManager = await ethers.getContractFactory("ProjectManager", {
      libraries: {
        Utilities: utilities.address,
      },
    });
    const projectManager = await ProjectManager.deploy();
    await projectManager.deployed();

    const TaskManager = await ethers.getContractFactory("TaskManager");
    const taskManager = await TaskManager.deploy();
    await taskManager.deployed();

    // Link the FundingsManager library contract to the StandardCampaign contract
    const StandardCampaign = await ethers.getContractFactory(
      "StandardCampaign",
      {
        libraries: {
          Utilities: utilities.address,
          FundingsManager: fundingsManager.address,
          CampaignManager: campaignManager.address,
          ProjectManager: projectManager.address,
          //TaskManager: taskManager.address,
        },
      }
    );
    standardCampaign = await StandardCampaign.deploy();
    await standardCampaign.deployed();

    // Deploy the Updatemaster contract
    const UpdateMaster = await ethers.getContractFactory("UpdateMaster", {
      libraries: {
        //Utilities: utilities.address,
        //FundingsManager: fundingsManager.address,
        CampaignManager: campaignManager.address,
        //ProjectManager: projectManager.address,
        //TaskManager: taskManager.address,
      },
    });
    updateMaster = await UpdateMaster.deploy(standardCampaign.address);
    await updateMaster.deployed();

    it("should connect UpdateMaster to standardcampaign", async function () {
      await standardCampaign.setUpdateMasterAddress(updateMaster.address);
    });

    const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    campaignOwner = owner;
    user1 = addr1;
  });

  it("should make a campaign", async function () {
    // Define the parameters
    const metadata = "My Campaign 1 on hardhat";
    const owners = [ethers.utils.getAddress(campaignOwner.address)];
    const acceptors = [ethers.utils.getAddress(randomWallets[1].address)];
    const stake = ethers.utils.parseEther("0.0025");
    const funding = ethers.utils.parseEther("0.0025");

    // Use the function
    const campaignId = await standardCampaign
      .connect(campaignOwner)
      .makeCampaign(metadata, owners, acceptors, stake, funding, {
        value: ethers.utils.parseEther("0.005"),
      });

    // Get the details of the campaign
    const campaign = await standardCampaign.getCampaign(1);

    // Print the campaign details
    console.log(campaign);
    console.log("Campaign: ", campaign.status == 1 ? "Running" : "Closed");
  });

  it("should make a project", async function () {
    // Define the parameters
    const _metadata = "My Project 1 in campaign 1 ";
    const _applicationRequired = true;
    const _parentCampaignId = 1;
    const _parentProjectId = 1;
    const _topLevel = true;

    const projectId = await standardCampaign
      .connect(campaignOwner)
      .makeProject(
        _metadata,
        _applicationRequired,
        _parentCampaignId,
        _parentProjectId,
        _topLevel
      );
  });

  it("should make a task", async function () {
    // Define the parameters
    const _metadata = "task 1 in project 1 in campaign 1";
    const weight = 65;
    const _deadline = 99999999999;
    const _parentProjectID = 1;

    const taskId = await standardCampaign
      .connect(campaignOwner)
      .makeTask(_metadata, weight, _deadline, _parentProjectID);
  });

  it("should apply to a project", async function () {
    // Define the parameters
    const _projectId = 1;
    const _metadata = "My application 0 to project 0";
    const _stake = ethers.utils.parseEther("0.025");

    const applicationId = await standardCampaign
      .connect(user1)
      .applyToProject(_projectId, _metadata, _stake, {
        value: ethers.utils.parseEther("0.025"),
      });
  });

  it("should get a campaign", async function () {
    const campaign = await standardCampaign.getCampaign(1);
    console.log("again", campaign);
  });

  // Add more test cases as needed
});
