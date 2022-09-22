const { ethers, upgrades } = require("hardhat");
const { Signer } = require("ethers");

async function main() {

    const [deployer, estateOwner] = await ethers.getSigners();
    console.log("Deploying Account:", await deployer.getAddress());


    const Estates = await ethers.getContractFactory("Estates");
    const estate = await upgrades.deployProxy(Estates, {kind: "uups"});
    await estate.deployed();
    console.log("contract deployed to:", estate.address);
  }
  
  main();