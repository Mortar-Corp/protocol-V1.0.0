const { ethers, upgrades } = require("hardhat");
const { BigNumber } =require("@ethersproject/bignumber");
const { Signer } = require("ethers");

async function main() {

  let minters = [];
  const [admin, upgrader, minter] = await ethers.getSigners();
  console.log("Admin Account:", await admin.getAddress());

  const AMP = await ethers.getContractFactory("Ampersand")
  const amp = await upgrades.deployProxy(AMP, [vct.address], 
    {initializer: "__Ampersand_init", kind: "uups", unsafeAllow: "delegatecall"})
  await amp.deployed()
  console.log("Ampersand address:", amp.address)


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



