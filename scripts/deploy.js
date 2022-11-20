const { ethers, upgrades } = require("hardhat");
const { BigNumber } =require("@ethersproject/bignumber");
const { Signer } = require("ethers");

async function main() {

  let minters = [];
  const [admin, upgrader, minter] = await ethers.getSigners();
  console.log("Admin Account:", await admin.getAddress());

  const VCT = await ethers.getContractFactory("VCToken");
  const vct = await upgrades.deployProxy(VCT, [process.env.UPGRADER], 
    {initializer: "__VCToken_init", kind: "uups", unsafeAllow: "delegatecall"})
  
  await vct.deployed()
  console.log("VCToken:", vct.address)
 


  const AMP = await ethers.getContractFactory("Ampersand")
  const amp = await upgrades.deployProxy(AMP, [vct.address], 
    {initializer: "__Ampersand_init", kind: "uups", unsafeAllow: "delegatecall"})
  await amp.deployed()
  console.log("Ampersand address:", amp.address)



  // const EstatesFactory = await ethers.getContractFactory("EstatesFactory");
  // const factory = await EstatesFactory.deploy();
  // await factory.deployed();
  // console.log("Estate Factory Address:", factory.address);
  // console.log("Deployer Address", Signer.address);

  // // We get the contract without deployment
  // const Estates = await ethers.getContractFactory("Estates");
  // //initialize upgradeable Beacon by using estates instance
  // const estateBeacon = await upgrades.deployBeacon(Estates.address, {initializer: "__EstatesFactory_init"});
  // await estateBeacon.deployed();
  // await estateBeacon.transferOwnership(deployer);

  // console.log("EstateBeacon Address:", estateBeacon.address);

  // //Im not sure if this is even makes sense
  // const tokenizeEstate = await upgrades.deployBeaconProxy(estateBeacon, [estateBeacon, Estates],{initializer: "__Estates_init.selector"})
}


main()
  .then(() => {
    console.log("\n Successful Deployment :)");
    process.existCode = 0;
  })
  .catch((error) => {
    console.log("\nFailed Deployment :(");
    console.error(error);
    process.exitCode = 1;
  });
