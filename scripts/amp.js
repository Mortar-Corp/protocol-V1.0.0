const { ethers, upgrades } = require("hardhat");
const { BigNumber } =require("@ethersproject/bignumber");


async function main() {

  const [owner, manager, minter1, minter2, minter3] = await ethers.getSigners();
  console.log("owner Account:", await owner.getAddress());

  const AMP = await ethers.getContractFactory("Ampersand")
  const amp = await upgrades.deployProxy(AMP, ["0x2354dd5262B66CC36dEACe1C15a2091823462665"], 
    {initializer: "__Ampersand_init", kind: "uups", unsafeAllow: "delegatecall"})
  await amp.deployed()
  console.log("Ampersand address:", amp.address)


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



