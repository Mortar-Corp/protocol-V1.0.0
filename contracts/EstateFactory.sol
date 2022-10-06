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
import "./VCToken.sol";




contract EstateFactory is Initializable, IEstateFactory, AccessControlUpgradeable, PausableUpgradeable {


  address private estateBeacon;
  address private estateProxy;
  address private constant VCT = 0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47;


  address[] private proxies;
  uint256 private proxyCount;
  mapping(address => address[]) private safeEstates;
  mapping(uint256 => bool) existing;

  //BRCK 1 = 10**9
  uint256 public constant LISTING_COST = 10e9;

  bytes32 public constant MANAGER_ROLE = keccak256(abi.encodePacked("MANAGER_ROLE"));
  bytes32 public constant UPGRADER_ROLE = keccak256(abi.encodePacked("UPGRADER_ROLE"));


  function __EstateFactory_init(address upgrader) public virtual override initializer {
    __AccessControl_init();
    __Pausable_init();

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(UPGRADER_ROLE, upgrader);
    
    UpgradeableBeacon _estateBeacon = new UpgradeableBeacon(address(new Estate()));
    _estateBeacon.transferOwnership(upgrader);
    estateBeacon = address(_estateBeacon);

    emit FactoryInit(_msgSender(), estateBeacon);
  }


  function tokenizeEstate(address safeAddress, uint256 taxId) public payable virtual override whenNotPaused returns(address) {
    require(IERC1155Modified(VCT).holderIdMinted(safeAddress) == true || IERC1155Modified(VCT).holderIdMinted(msg.sender) == true,
    "EstateFactory: only allowed to verified credential holders");
    require(!existing[taxId], "EstateFactory: tax ID exists");
    existing[taxId] = true;
    require(msg.value >= LISTING_COST, "EstateFactory: listing cost is 1 BRCK");
    BeaconProxy proxy = new BeaconProxy(
      estateBeacon, 
      abi.encodeWithSelector(
        Estate(address(0)).__Estate_init.selector, 
        safeAddress, 
        msg.sender, 
        taxId
      )
    );


    estateProxy = address(proxy);
    proxyCount = proxies.length;

    proxies.push(estateProxy);

    safeEstates[safeAddress].push(estateProxy);

    emit ProxyDeployed(proxyCount, estateProxy, safeAddress, _msgSender());
    
    return estateProxy;
  }  

  function setManager(address manager) public virtual onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
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