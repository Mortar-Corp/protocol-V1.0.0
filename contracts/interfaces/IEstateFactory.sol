//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


interface IEstateFactory {
    event FactoryInit(address indexed upgrader, address estateBeacon);
    
    event ProxyDeployed
    (
        uint256 proxyId, 
        address proxyAddress, 
        address indexed safeAddress, 
        address indexed initiator 
    );
    

    function __EstateFactory_init(address upgrader) external;


    function tokenizeEstate(address safeAddress, uint256 taxId) external returns(address);


    function allOwnerEstates(address owner) external view returns(address[] memory);

    function totalOwnerEstates(address owner) external view returns(uint256);

    function ownerEstateAddr(address owner, uint256 id) external view returns(address);

    function contractAddr(uint256 taxId) external view returns(address);

    function allProxies() external view returns(address[] memory);

    function proxiesCount() external view returns(uint256);

    function proxyAddrById(uint256 num) external view returns(address);

    function modifyProxyURI(address estateContract, uint256 tokenId, string memory newURI) external returns(bool);

    function modifyProxyMetadata(address estateContract, uint256 tokenId, string memory newName, string memory newSymbol) external returns(bool);

    function emergencyPause() external;

    function emergencyUnpause() external;

    function isPaused() external view returns(bool);

}