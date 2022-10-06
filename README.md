# Protocol-V1.0.0

## Testnet Deployment: cement

The repository consists of the following contracts:

**1. VCToken:** Verified Credential Token at a constant address 0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47 - has to be updated every time redeployed.

There 5 available tokens as follows:

1. BUSINESS: US-based business is only allowed.
2. US_PERSON: US-citizen registering with SSN 
3. INT_PERSON: Global individual registering with valid Gov-Id and valid passport.
4. US_ACCREDITED_INVESTOR: US-citizen Accredited Investor
5. INT_ACCREDITED_INVESTOR: non Us-citizen Accredited Investor

*Note: EIP712 & signature checker is used to verify user*


**2. IERC1155Modified:** OZ modified IERC1155Upgradeable since `mintBatch` and all batch related functions will never be used. This is the interface of `VCToken`

**3. Estate:** is the logic contract used to initiate `BeaconProxy` for each estate:

 - estate owner: can choose token name, token symbol, & token URI.
 - can mint one token for each contract 
 - mint requires at least 2 BRCK to go through

**4. IERC721Modified:** OZ IERC721Upgradeable contract modified which is the interface of `Estate` contract.

**5. EstateFactory:** deployed with `UpgradeableBeacon` to initiate logic and based on different access levels of control:

 1. `DEFAULT_AMIN_ROLE`: is the contract deployer
 2. `UPGRADER_ROLE`: responsible for upgradeability, pausing, & unpausing operations.
 3. `MANAGER_ROLE`: can change proxy token name, symbol, &/or URI when necessary.

 - owner will not be able to list his estate unless he is verified
 - listing require a min 1 BRCK to be able to list your estate

