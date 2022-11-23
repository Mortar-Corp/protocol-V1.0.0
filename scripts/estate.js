const { ethers, upgrades } = require("hardhat");
const { BigNumber } =require("@ethersproject/bignumber");
const { Signer } = require("ethers");

async function main() {

    const[admin, upgrader] = await ethers.getSigners();
    console.log("admin address:", admin.getAddress());

    //validate Imp without deployment
    //https://docs.openzeppelin.com/upgrades-plugins/1.x/api-hardhat-upgrades

    const Imp = await ethers.getContractFactory("Estate");
    //await upgrades.validateImplementation(Imp, {kind: "beacon"});

    const Factory = await ethers.getContractFactory("Factory");
    const factory = await upgrades.deployBeacon(Factory, [process.env.UPGRADER], 
        {initializer: "__EstateFactory_init", kind: "beacon"})

    console.log("factory address:", factory.address)


}
main()
  .then(() => {
    console.log("\nSuccessful Deployment :)");
    process.existCode = 0;
  })
  .catch((error) => {
    console.log("\nFailed Deployment :(");
    console.error(error);
    process.exitCode = 1;
  });