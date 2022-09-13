//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./proxy/Initializable.sol";
import "./security/PausableUpgradeable.sol";
import "./proxy/BeaconProxy.sol";
import "./proxy/UpgradeableBeacon.sol";
import "./Estates.sol";
import "./IEstatesFactory.sol";


contract EstatesFactory is IEstatesFactory, Initializable, PausableUpgradeable {

  address private mortarchain;
  address private estateBeacon;
  address private estateProxy;
  address private _estateOwner;


  
  mapping(address => address[]) private proxyManagers;
  address[] private proxies;
  mapping(address => address) private ownerContract;



  modifier onlyMortar {
    require(msg.sender == mortarchain,"Factory: only mortar");
    _;
  }


  function __EstatesFactory_init() public virtual override initializer {
    mortarchain = _msgSender();
    UpgradeableBeacon _estateBeacon = new UpgradeableBeacon(address(new Estates()));
    _estateBeacon.transferOwnership(mortarchain);
    estateBeacon = address(_estateBeacon);

    emit FactoryInit(_msgSender(), estateBeacon);
  }


  function tokenizeEstate(address estateManager, address estateOwner) public virtual onlyMortar whenNotPaused returns(address) {
    BeaconProxy proxy = new BeaconProxy(estateBeacon, abi.encodeWithSelector(Estates(address(0)).__Estates_init.selector, estateManager, estateOwner));

    _estateOwner = estateOwner;

    estateProxy = address(proxy);
    uint256 proxyCount = proxies.length;

    proxies.push(estateProxy);
    proxyManagers[estateManager].push(estateProxy);

    ownerContract[_estateOwner] = estateProxy;

    emit ProxyDeployed(proxyCount, estateProxy, estateOwner, estateManager);
    
    return estateProxy;
  }  

  function proxyByEstateOwner(address owner) external view virtual override returns(address) {
    return ownerContract[owner];
  }

  function deployerAddress() external view virtual override returns(address) {
    return mortarchain;
  }

  function getEstateBeacon() external view virtual returns(address) {
    return estateBeacon;
  }

  function allProxies() external view virtual override returns(address[] memory) {
    return proxies;
  }

  function proxiesManager(address manager) external view virtual override returns(address[] memory){
    return proxyManagers[manager];
  }

  function proxiesCount() external view virtual override returns(uint256) {
    return proxies.length;
  }

  function proxyAddrById(uint256 num) external view returns(address) {
    return proxies[num];
  }

  function emergencyPause() external virtual override onlyMortar {
    _pause();
  }

  function emergencyUnpause() external virtual override onlyMortar {
    _unpause();
  }

}