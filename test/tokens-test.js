const { expect } = require("chai");
const { ethers, upgrades} = require("hardhat");

describe("Tokens", function() {
    it('works', async () => {
      const Tokens = await ethers.getContractFactory("VCTokens");
    
    
      const instance = await upgrades.deployProxy(Tokens, {kind: "uups"});
     

      expect(await instance.name() === "VCToken");

    });
  });

