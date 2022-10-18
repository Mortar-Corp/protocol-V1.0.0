//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IVaultFactory {

    event UpgradeableProxy(address indexed vaultBeacon);

    event ProxyDeployed(address indexed vaultProxy, uint256 vaultId);

    event AssetListed
    (
        address indexed nftAddress, 
        uint256 tokenId, 
        address sellerSafe, 
        address indexed seller, 
        uint256 price
    );

    function __VaultFactory_init()external;

    function initiateVault
    (
        address nftAddress, 
        uint256 tokenId, 
        string memory name, 
        string memory symbol, 
        uint256 askPrice, 
        address safe
    ) external payable returns(address, uint256);

    function isOpsPaused() external view returns(bool);

    function pauseOps() external;

    function unpauseOps() external;

    function vaultAddress(uint256 id) external view returns(address);

    function upgradeBeaconAddress() external returns(address);

    function ownerUpgrader() external view returns(address);

    function vaultOfNft(address nftAddress) external view returns(address);
}