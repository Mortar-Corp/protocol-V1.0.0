const { ethers, upgrades } = require("hardhat");
const { Signer } = require("ethers");

async function main() {

  const [deployer] = await ethers.getSigners();
  console.log("Mortar Deployer Account:", await deployer.getAddress());



  const EstatesFactory = await ethers.getContractFactory("EstatesFactory");
  const factory = await EstatesFactory.deploy();
  await factory.deployed();
  console.log("Estate Factory Address:", factory.address);
  console.log("Deployer Address", Signer.address);

  // We get the contract without deployment
  const Estates = await ethers.getContractFactory("Estates");
  //initialize upgradeable Beacon by using estates instance
  const estateBeacon = await upgrades.deployBeacon(Estates.address, {initializer: "__EstatesFactory_init"});
  await estateBeacon.deployed();
  await estateBeacon.transferOwnership(deployer);

  console.log("EstateBeacon Address:", estateBeacon.address);

  //Im not sure if this is even makes sense
  const tokenizeEstate = await upgrades.deployBeaconProxy(estateBeacon, [estateBeacon, Estates],{initializer: "__Estates_init.selector"})
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.log("\nFailed Deployment !")
  console.error(error);
  process.exitCode = 1;
});
