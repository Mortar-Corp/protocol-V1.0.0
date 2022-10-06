//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


interface IEstateFactory {

    //emitted when factory contract is deployed by `deployer` & `estateBeacon`
    event FactoryInit(address indexed upgrader, address estateBeacon);
    
    //emitted when `estateOwner` & `estateManager` is assigned by `deployer` to initiate `proxyAddress` that has `proxyId`
    event ProxyDeployed
    (
        uint256 proxyId, 
        address proxyAddress, 
        address indexed safeAddress, 
        address indexed initiator 
    );
    
    /**
     *@notice  mortar address is the deployer address which has upgradability & super 
     * managerial features that includes assigning `estateManager` & `estateOwner`
     * pausing & unpausing operations.
     *
     * emits `FactoryInit` event
     */
    function __EstateFactory_init(address upgrader) external;


    function tokenizeEstate(address safeAddress, uint256 taxId) external payable returns(address);

    //gets proxy contract address `estateOwner` address
    function allSafeEstates(address safeAddress) external view returns(address[] memory);

    //gets an array of all proxy addresses
    function allProxies() external view returns(address[] memory);

    // //gets an array of all proxy addresses managed by `manager` address
    // function proxiesManager(address manager) external view returns(address[] memory);

    //gets total count of proxies
    function proxiesCount() external view returns(uint256);

    //gets proxy address by it's `num`
    function proxyAddrById(uint256 num) external view returns(address);

    function modifyProxyURI(address estateContract, uint256 tokenId, string memory newURI) external returns(bool);

    function modifyProxyMetadata(address estateContract, uint256 tokenId, string memory newName, string memory newSymbol) external returns(bool);

    //only mortar address can pause & unpause 
    function emergencyPause() external;

    function emergencyUnpause() external;

    function isPaused() external view returns(bool);

}