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

contract VaultFactory is Initializable, IVaultFactory, PausableUpgradeable {

    address private vaultBeacon; //
    uint256 private vaultId;   //
    address private mrtr;

    mapping(uint256 => address) private vaults; //
    mapping(address => address) private assetVault;


    address private constant VCT = 0xf8e81D47203A594245E36C48e151709F0C19fBe8;

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
        uint256 nftId, 
        uint256 price,
        uint256 supply,
        string memory name_, 
        string memory symbol_, 
        address safe
    ) public virtual override whenNotPaused returns(address, uint256) {
        require(price > 0 && supply > 0, "VaultFactory: price or supply is zero");
        require(
            AddressUpgradeable.isContract(safe) && safe != address(0), 
            "VaultFactory: safe is not contract or zero address"
        );
        require(
            IERC1155Modified(VCT).isVerified(msg.sender),
            "VaultFactory: verified holders only"
        );
        
        BeaconProxy proxy = new BeaconProxy
        (
            vaultBeacon, 
            abi.encodeWithSelector
            (
                Vault(address(0)).__Vault_init.selector, 
                nftAddress,
                nftId, 
                price, 
                supply,
                name_,
                symbol_, 
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
        emit AssetListed(nftAddress, nftId, safe, msg.sender, price);
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
