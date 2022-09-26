require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-gas-reporter");


module.exports = {
  networks: {
    mrtrTest: {
      url: `http://35.202.235.89:8545/`,
      chainId: 1031,
      accounts: [process.env.MRTR_PRIVATE_KEY],
      timeout: 80000,   
    },
  },
  gasReporter: {
    coinmarketcap: process.env.COINMARKETCAP,
    //token: "BRCK", //we need a Mrtr API to report correctly 
    currency: "USD",  //I need coinMarketCap API to report in usd;
    gasPrice: 200,    //our gasPrice?
  },

  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    }
  },
  paths: {
    sources: "./contracts",
    scripts: "./scripts",
    tests: "./test",
    artifacts: "./artifacts",
    cache: "./cache",

  }
};
