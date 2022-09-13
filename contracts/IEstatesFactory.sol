//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IEstatesFactory {

    //emitted when factory contract is deployed by `deployer` & `estateBeacon`
    event FactoryInit(address indexed deployer, address estateBeacon);
    
    //emitted when `estateOwner` & `estateManager` is assigned by `deployer` to initiate `proxyAddress` that has `proxyId`
    event ProxyDeployed(uint256 proxyId, address proxyAddress, address indexed estateOwner, address indexed estateManager);
    
    /**
     *@notice  mortar address is the deployer address which has upgradability & super 
     * managerial features that includes assigning `estateManager` & `estateOwner`
     * pausing & unpausing operations.
     *
     * emits `FactoryInit` event
     */
    function __EstatesFactory_init() external;

    /**
     *@param estateManager address, manager of the initiated proxy
     *@param estateOwner address, property owner address
     *
     *Requirement:
     * only mortar address can assign `estateManager` & `estateOwner`
     * 
     * emits `ProxyDeployed` event
     */
    function tokenizeEstate(address estateManager, address estateOwner) external returns(address);

    //gets `deployerAddress` which is mortar address
    function deployerAddress() external view returns(address);

    //gets proxy contract address `estateOwner` address
    function proxyByEstateOwner(address owner) external view returns(address);

    //gets an array of all proxy addresses
    function allProxies() external view returns(address[] memory);

    //gets an array of all proxy addresses managed by `manager` address
    function proxiesManager(address manager) external view returns(address[] memory);

    //gets total count of proxies
    function proxiesCount() external view returns(uint256);

    //gets proxy address by it's `num`
    function proxyAddrById(uint256 num) external view returns(address);

    //only mortar address can pause & unpause 
    function emergencyPause() external;

    function emergencyUnpause() external;

}