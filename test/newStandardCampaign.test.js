const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StandardCampaign", function () {

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

    const TaskManager = await ethers.getContractFactory("TaskManager", {
      libraries: {
        FundingsManager: fundingsManager.address,
      },
    });
    const taskManager = await TaskManager.deploy();
    await taskManager.deployed();

    // Link the FundingsManager library contract to the StandardCampaign contract
    const StandardCampaign = await ethers.getContractFactory("StandardCampaign", {
      libraries: {
        Utilities: utilities.address,
        FundingsManager: fundingsManager.address,
        CampaignManager: campaignManager.address,
        ProjectManager: projectManager.address,
        TaskManager: taskManager.address,
      },
    });
    const standardCampaign = await StandardCampaign.deploy();
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