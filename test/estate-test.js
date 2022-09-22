const { expect, assert } = require("chai");
const { ethers, upgrades} = require("hardhat");

describe("Estates", function() {
    it('works', async () => {
      const Estates = await ethers.getContractFactory("Estates");
    
    
      const instance = await upgrades.deployProxy(Estates, {kind: "uups"});
     

      assert(await instance.version() === "V1.0.0");
      

    });
  });