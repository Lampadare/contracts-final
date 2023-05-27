require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      // Other Solidity compiler options...
      optimizer: {
        enabled: true,
        runs: 1
      }
    },
  },
};
