const { expect } = require("chai");
const { ethers, upgrades, hre} = require("hardhat");

describe("Tokens", function() {
    it('works', async () => {
      const Tokens = await ethers.getContractFactory("VCTokens");
    
    
      const instance = await upgrades.deployProxy(Tokens, {kind: "uups"});
     
  

      expect(await instance.name() === "VCToken");
    });
  });

// before("get factories", async function () {
//     this.VCTokens = await hre.ethers.getContractFactory("VCTokens");
// });

// it('works', async function ()  {
   
//     const instance = await hre.upgrades.deployProxy(this.VCTokens, {kind: "uups"});
    
//     assert(await instance.name() === "VCToken");
//   });
