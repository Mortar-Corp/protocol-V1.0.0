const { ethers, upgrades } = require("hardhat");
const { BigNumber } =require("@ethersproject/bignumber");
const { Signer } = require("ethers");

async function main() {

  let minters = [];
  let tokenId = [1, 2, 3, 4, 5];
  const [admin, upgrader, minter] = await ethers.getSigners();
  console.log("Admin Account:", await admin.getAddress());

  const VCT = await ethers.getContractFactory("VCToken");
  const vct = await upgrades.deployProxy(VCT, [process.env.UPGRADER], 
    {initializer: "__VCToken_init", kind: "uups", unsafeAllow: "delegatecall"})
  
  await vct.deployed()
  console.log("VCToken:", vct.address)

  //vct.setMinter(minter.address, tokenId)
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



