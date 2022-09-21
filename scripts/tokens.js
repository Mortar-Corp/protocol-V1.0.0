const { ethers, upgrades } = require("hardhat");
const { Signer } = require("ethers");

async function main() {

    const [deployer] = await ethers.getSigners();
    console.log("Deploying Account:", await deployer.getAddress());


    const Token = await ethers.getContractFactory("VCTokens");
    const token = await upgrades.deployProxy(Token, {kind: "uups"});
    await token.deployed();
    console.log("contract deployed to:", token.address);
  }
  
  main();