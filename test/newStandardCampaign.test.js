const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StandardCampaign", function () {
  let CampaignManager;
  let FundingsManager;
  let ProjectManager;
  let TaskManager;
  let Utilities;
  let StandardCampaign;
  let Checkers;

  beforeEach(async function () {
    // Get the contract factories for the library contracts
    CampaignManager = await ethers.getContractFactory("CampaignManager");
    FundingsManager = await ethers.getContractFactory("FundingsManager");
    ProjectManager = await ethers.getContractFactory("ProjectManager");
    TaskManager = await ethers.getContractFactory("TaskManager");
    Utilities = await ethers.getContractFactory("Utilities");

    // Deploy the library contracts
    const fundingsManager = await FundingsManager.deploy();
    const projectManager = await ProjectManager.deploy();
    const taskManager = await TaskManager.deploy();
    const utilities = await Utilities.deploy();

    // Deploy the CAMPAIGNMANAGER contract
    CampaignManager = await ethers.getContractFactory("NewStandardCampaign", {
      libraries: {
        CampaignManager: campaignManager.address,
        FundingsManager: fundingsManager.address,
        ProjectManager: projectManager.address,
        TaskManager: taskManager.address,
        Utilities: utilities.address,
      },
    });
    const campaignManager = await CampaignManager.deploy();
    await campaignManager.deployed();

    // Deploy the PROJECTMANAGER contract
    ProjectManager = await ethers.getContractFactory("NewStandardCampaign", {
      libraries: {
        CampaignManager: campaignManager.address,
        FundingsManager: fundingsManager.address,
        ProjectManager: projectManager.address,
        TaskManager: taskManager.address,
        Utilities: utilities.address,
      },
    });
    await projectManager.deployed();

    // Deploy the TASKMANAGER contract 
    TaskManager = await ethers.getContractFactory("NewStandardCampaign", {
      libraries: {
        CampaignManager: campaignManager.address,
        FundingsManager: fundingsManager.address,
        ProjectManager: projectManager.address,
        TaskManager: taskManager.address,
        Utilities: utilities.address,
      },
    });
    await taskManager.deployed();

    // Link the FundingsManager library contract to the StandardCampaign contract
    StandardCampaign = await ethers.getContractFactory("NewStandardCampaign", {
      libraries: {
        CampaignManager: campaignManager.address,
        FundingsManager: fundingsManager.address,
        ProjectManager: projectManager.address,
        TaskManager: taskManager.address,
        Utilities: utilities.address,
      },
    });
    const standardCampaign = await Campaign.deploy();
    await standardCampaign.deployed();

  });

  it("should allow a worker to vote", async function () {
    const metadata = "My Campaign";
    const owners = [ethers.utils.getAddress("0x123..."), ethers.utils.getAddress("0x456...")];
    const acceptors = [ethers.utils.getAddress("0x789..."), ethers.utils.getAddress("0xabc...")];
    const stake = ethers.utils.parseEther("0.0025");
    const funding = ethers.utils.parseEther("0.0025");
    const campaignId = await campaign.makeCampaign(metadata, owners, acceptors, stake, funding, { value: ethers.utils.parseEther("1") });
  });

  // Add more test cases as needed
});