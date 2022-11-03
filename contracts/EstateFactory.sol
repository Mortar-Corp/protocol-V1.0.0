//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./proxy/Initializable.sol";
import "./access/AccessControlUpgradeable.sol";
import "./security/PausableUpgradeable.sol";
import "./proxy/BeaconProxy.sol";
import "./proxy/UpgradeableBeacon.sol";
import "./interfaces/IEstateFactory.sol";
import "./interfaces/IERC721Modified.sol";
import "./interfaces/IERC1155Modified.sol";
import "./Estate.sol";


contract EstateFactory is Initializable, IEstateFactory, AccessControlUpgradeable, PausableUpgradeable {


  address private estateBeacon;
  address private constant VCT = 0xf8e81D47203A594245E36C48e151709F0C19fBe8;


  address[] private proxies;
  mapping(address => address[]) private ownerEstates;
  mapping(uint256 => address) private taxAddress;
  mapping(uint256 => bool) existing;

  bytes32 public constant ADMIN_ROLE = keccak256(abi.encodePacked("ADMIN_ROLE"));
  bytes32 public constant MANAGER_ROLE = keccak256(abi.encodePacked("MANAGER_ROLE"));
  bytes32 public constant UPGRADER_ROLE = keccak256(abi.encodePacked("UPGRADER_ROLE"));


  function __EstateFactory_init(address upgrader) public virtual override initializer {
    __AccessControl_init();
    __Pausable_init();

    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);
    _setupRole(ADMIN_ROLE, _msgSender());
    _setupRole(UPGRADER_ROLE, upgrader);
    
    UpgradeableBeacon _estateBeacon = new UpgradeableBeacon(address(new Estate()));
    _estateBeacon.transferOwnership(upgrader);
    estateBeacon = address(_estateBeacon);

    emit FactoryInit(_msgSender(), estateBeacon);
  }


  function tokenizeEstate(address safeAddress, uint256 taxId) public virtual override whenNotPaused returns(address) {
    require(IERC1155Modified(VCT).isVerified(msg.sender),"EstateFactory: verified holders only");
    require(!existing[taxId], "EstateFactory: tax ID exists");
    existing[taxId] = true;

    BeaconProxy proxy = new BeaconProxy(
      estateBeacon, 
      abi.encodeWithSelector(
        Estate(address(0)).__Estate_init.selector, 
        safeAddress, 
        msg.sender, 
        taxId
      )
    );

    address estateProxy = address(proxy);
    proxies.push(estateProxy);
    uint256 proxyCount = proxies.length;
    Estate(estateProxy).transferOwnership(msg.sender);
    
    taxAddress[taxId] = estateProxy;

    ownerEstates[msg.sender].push(estateProxy);
   
    emit ProxyDeployed(proxyCount, estateProxy, safeAddress, _msgSender());
    
    return estateProxy;
  }  

  function setManager(address manager) public virtual onlyRole(ADMIN_ROLE) returns(bool) {
    _grantRole(MANAGER_ROLE, manager);
    return hasRole(MANAGER_ROLE, manager);
  }

  function modifyProxyURI(address estateContract, uint256 tokenId, string memory newURI) public virtual override onlyRole(MANAGER_ROLE) whenNotPaused returns(bool){
    (bool success, ) = 
    estateContract.call(abi.encodeWithSelector(Estate.modifyTokenURI.selector, tokenId, newURI));
    require(success, "EstateFactory: modify URI failed");
    return  success;
  }

  function modifyProxyMetadata(address estateContract, uint256 tokenId, string memory newName, string memory newSymbol) public virtual override onlyRole(MANAGER_ROLE) whenNotPaused returns(bool) {
    (bool success, ) = 
    estateContract.call(abi.encodeWithSelector(Estate.modifyTokenMetadata.selector, tokenId, newName, newSymbol));
    require(success, "EstateFactory: modify metadata failed");
    return success;
  }

  function allOwnerEstates(address owner) external view virtual override returns(address[] memory) {
    return ownerEstates[owner];
  }

  function totalOwnerEstates(address owner) external view virtual override returns(uint256) {
    return ownerEstates[owner].length;
  }

  function ownerEstateAddr(address owner, uint256 id) external view virtual override returns(address) {
    return ownerEstates[owner][id];
  }

  function contractAddr(uint256 taxId) external view virtual override returns(address) {
    return taxAddress[taxId];
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

  function taxIdExists(uint256 taxId) public view returns(bool) {
    return existing[taxId];
  }

  function emergencyPause() external virtual override onlyRole(UPGRADER_ROLE) {
    _pause();
  }

  function emergencyUnpause() external virtual override onlyRole(UPGRADER_ROLE) {
    _unpause();
  }

  function isPaused() public view virtual override returns(bool) {
    return paused();
  }


}