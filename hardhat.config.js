require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-gas-reporter");
require("solidity-coverage");
//const privateKeys = process.env.PRIVATE_KEYS || "";

module.exports = {
  networks: {
    mrtrTest: {
      url: `http://35.238.106.48:8545`,
      chainId: 1031,
      from: [`0x${process.env.MRTR_PRIVATE_KEY}`],
      timeout: 20000,   //Cormac: default for Jason-rpc based networks
    },
  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS) ? true : false,
    token: "BRCK",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  solidity: {
    version: "0.8.13",
    optimizer: {
      enabled: true,
      runs: 10000,
    }
  }
};
