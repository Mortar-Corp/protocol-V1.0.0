const { ethers, upgrades } = require("hardhat");
const { BigNumber } =require("@ethersproject/bignumber");
const { Signer } = require("ethers");

async function main() {

  const [admin, upgrader] = await ethers.getSigners();
  console.log("Admin Account:", await admin.getAddress());

  const VCT = await ethers.getContractFactory("VCToken");
  const vct = await upgrades.deployProxy(VCT, [process.env.UPGRADER], 
    {initializer: "__VCToken_init", kind: "uups", unsafeAllow: "delegatecall"})
  await vct.deployed()
  console.log("VCToken:", vct.address)

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



