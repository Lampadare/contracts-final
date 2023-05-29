require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      // Other Solidity compiler options...
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
  },
  gasReporter: {
    currency: "CHF",
    gasPrice: 21,
  },
};
