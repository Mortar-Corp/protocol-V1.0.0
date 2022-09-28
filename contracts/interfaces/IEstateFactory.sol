//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


interface IEstateFactory {

    //emitted when factory contract is deployed by `upgrader` & initiate`estateBeacon`
    event FactoryInit(address indexed upgrader, address estateBeacon);
    
    /**  
     * emitted when `deployer` initiate `proxyAddress` that has `proxyId` 
     * & list `safeAddress` where tokens will be minted.
     */
    event ProxyDeployed
    (
        uint256 proxyId, 
        address proxyAddress, 
        address indexed safeAddress, 
        address indexed deployer 
    );
    
    /**
     *@notice  deployer is the `owner` of factory responsible of upgradability,
     * pausing & unpausing operations.
     *
     * emits `FactoryInit` event
     */
    function __EstateFactory_init() external;


    function tokenizeEstate(address safeAddress) external returns(address);


    //gets proxy contract address `estateOwner` address
    function allSafeEstates(address safeAddress) external view returns(address[] memory);

    //gets an array of all proxy addresses
    function allProxies() external view returns(address[] memory);

    //gets total count of proxies
    function proxiesCount() external view returns(uint256);

    //gets proxy address by it's `num`
    function proxyAddrById(uint256 num) external view returns(address);

 
    function emergencyPause() external;

    function emergencyUnpause() external;

}