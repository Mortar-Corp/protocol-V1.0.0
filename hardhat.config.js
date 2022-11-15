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
    goerli: {
      url: `https://goerli.infura.io/v3/`,
      chainId: 5,
      accounts: [],
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/`,
      chainId: 11155111,
      accounts: [],
    },
    mumbai: {
      url: `https://matic-mumbai.chainstacklabs.com`,
      chainId: 80001,
      accounts: [],
    },
    bnbTest: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      chainId: 97,
      confirmations: 25,
      timeout: 3000,
      skipDryRun: true
    }
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
