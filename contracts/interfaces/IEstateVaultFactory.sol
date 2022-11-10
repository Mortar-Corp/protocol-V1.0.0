//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IEstateVaultFactory {

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

    function __EstateVaultFactory_init()external;

    function initiateVault
    (
        address nftAddress, 
        uint256 nftId, 
        uint256 price,
        uint256 supply,
        string memory name, 
        string memory symbol, 
        address safe
    ) external returns(address, uint256);

    function isOpsPaused() external view returns(bool);

    function pauseOps() external;

    function unpauseOps() external;

    function vaultAddress(uint256 id) external view returns(address);

    function upgradeBeaconAddress() external returns(address);

    function vaultOfNft(address nftAddress) external view returns(address);
}