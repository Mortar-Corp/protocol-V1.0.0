//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./Vault.sol";
import "./proxy/Initializable.sol";
import "./proxy/UpgradeableBeacon.sol";
import "./proxy/BeaconProxy.sol";
import "./security/PausableUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IERC1155Modified.sol";

/**
 *@title VaultFactory
 *@author Sasha Flores
 *@dev only VCT holders are allowed to list their nft.
 * any nft is allowed to
 
 */
contract VaultFactory is Initializable, IVaultFactory, PausableUpgradeable {

    address private vaultBeacon; 
    uint256 private vaultId;   
    address private mrtr;

    mapping(uint256 => address) private vaults; 
    mapping(address => address) private assetVault;

    uint256 private constant LISTING_FEE = 1 * 10**9;
    
    address private constant VCT = 0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c;

    function __VaultFactory_init() public virtual override initializer {
        __Pausable_init();
        mrtr = msg.sender;
        UpgradeableBeacon instance = new UpgradeableBeacon(address(new Vault()));
        instance.transferOwnership(mrtr);
        vaultBeacon = address(instance);
        emit UpgradeableProxy(vaultBeacon);
    }

    function initiateVault
    (
        address nftAddress, 
        uint256 tokenId, 
        string memory name, 
        string memory symbol, 
        uint256 askPrice, 
        address safe
    ) public payable
    virtual 
    override 
    whenNotPaused 
    returns(address, uint256) {
        require(askPrice > 0, "VaultFactory: price is zero");
        require(
            AddressUpgradeable.isContract(safe) && safe != address(0), 
            "VaultFactory: safe is not contract or zero address"
        );
        require(
            IERC1155Modified(VCT).isVerified(safe) || 
            IERC1155Modified(VCT).isVerified(msg.sender),
            "VaultFactory: verified holders only"
        );
        require(msg.value >= LISTING_FEE, "VaultFactory: listing fee is 1 BRCK");
        
        BeaconProxy proxy = new BeaconProxy
        (
            vaultBeacon, 
            abi.encodeWithSelector
            (
                Vault(address(0)).__Vault_init.selector, 
                nftAddress,
                tokenId, 
                name, 
                symbol, 
                askPrice, 
                safe, 
                msg.sender
            )
        );
        
        address vault = address(proxy);
        Vault(vault).transferOwnership(mrtr);
        vaults[vaultId] = vault;
        vaultId ++;

        assetVault[nftAddress] = vault;

        emit ProxyDeployed(vault, vaultId);
        emit AssetListed(nftAddress, tokenId, safe, msg.sender, askPrice);
        return (vault, vaultId - 1);
    }

    function pauseOps() public virtual override {
        require(msg.sender == mrtr, "VaultFactory: only mortar");
        _pause();
    }

    function unpauseOps() public virtual override {
        require(msg.sender == mrtr, "VaultFactory: only mortar");
        _unpause();
    }

    function isOpsPaused() public view virtual override returns(bool) {
        return paused();
    }

    function vaultAddress(uint256 id) external view virtual override returns(address) {
        return vaults[id];
    }

    function upgradeBeaconAddress() external view virtual override returns(address) {
        return vaultBeacon;
    }

    function ownerUpgrader() external view virtual override returns(address) {
        return mrtr;
    }

    function vaultOfNft(address nftAddress) external view virtual override returns(address) {
        return assetVault[nftAddress];
    }
   
}
