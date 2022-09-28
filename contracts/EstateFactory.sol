//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./proxy/Initializable.sol";
import "./access/OwnableUpgradeable.sol";
import "./security/PausableUpgradeable.sol";
import "./proxy/BeaconProxy.sol";
import "./proxy/UpgradeableBeacon.sol";
import "./interfaces/IEstateFactory.sol";
import "./Estate.sol";
import "./VCToken.sol";



contract EstateFactory is Initializable, IEstateFactory, OwnableUpgradeable, PausableUpgradeable {


  address private estateBeacon;
  address private estateProxy;
  VCToken private VCT;




  address[] private proxies;
  mapping(address => address[]) private safeEstates;



  function __EstateFactory_init() public virtual override initializer {
    __Ownable_init();
    __Pausable_init();

    UpgradeableBeacon _estateBeacon = new UpgradeableBeacon(address(new Estate()));
    _estateBeacon.transferOwnership(_msgSender());
    estateBeacon = address(_estateBeacon);

    emit FactoryInit(_msgSender(), estateBeacon);
  }


  function tokenizeEstate(address safeAddress) public virtual override whenNotPaused returns(address) {
    require(VCT.holderIdMinted(safeAddress) == true || VCT.holderIdMinted(msg.sender) == true,
    "EstateFactory: only allowed to verified credential holders");
    BeaconProxy proxy = new BeaconProxy(estateBeacon, abi.encodeWithSelector(Estate(address(0)).__Estate_init.selector, safeAddress, msg.sender));


    estateProxy = address(proxy);
    uint256 proxyCount = proxies.length;

    proxies.push(estateProxy);

    safeEstates[safeAddress].push(estateProxy);

    emit ProxyDeployed(proxyCount, estateProxy, safeAddress, _msgSender());
    
    return estateProxy;
  }  

  function allSafeEstates(address safeAddress) external view virtual override returns(address[] memory) {
    return safeEstates[safeAddress];
  }


  function getEstateBeacon() external view virtual returns(address) {
    return estateBeacon;
  }

  function allProxies() external view virtual override returns(address[] memory) {
    return proxies;
  }

  function proxiesCount() external view virtual override returns(uint256) {
    return proxies.length;
  }

  function proxyAddrById(uint256 num) external view override returns(address) {
    return proxies[num];
  }

  function emergencyPause() external virtual override onlyOwner {
    _pause();
  }

  function emergencyUnpause() external virtual override onlyOwner {
    _unpause();
  }

}