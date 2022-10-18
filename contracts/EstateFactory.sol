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
import "./VCTest.sol";

/**
 *@title EstateFactory
 *@author Sasha Flores
 *@dev only accessible to VCT holders, with taxid as filter to prevent 
 * dupliacte listing of any estate, with listing fee of 1 BRCK.
 */

contract EstateFactory is Initializable, IEstateFactory, AccessControlUpgradeable, PausableUpgradeable {


  address private estateBeacon;
  address private constant VCT = 0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c;


  address[] private proxies;
  mapping(address => address[]) private safeEstates;
  mapping(uint256 => bool) existing;

  //BRCK 1 = 10**9
  uint256 public  constant BASE = 10e9;
  uint256 public constant LISTING_FEE = 1 * BASE;

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


  function tokenizeEstate(address safeAddress, uint256 taxId) public payable virtual override whenNotPaused returns(address) {
    require(
      IERC1155Modified(VCT).isVerified(safeAddress) || 
      IERC1155Modified(VCT).isVerified(msg.sender),
      "EstateFactory: verified holders only"
    );
    require(!existing[taxId], "EstateFactory: tax ID exists");
    existing[taxId] = true;
    require(msg.value >= LISTING_FEE, "EstateFactory: listing cost is 1 BRCK");
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
    uint256 proxyCount = proxies.length;
    Estate(estateProxy).transferOwnership(msg.sender);
    proxies.push(estateProxy);
    safeEstates[safeAddress].push(estateProxy);

    emit ProxyDeployed(proxyCount, estateProxy, safeAddress, _msgSender());
    
    return estateProxy;
  }  

  function setManager(address manager) public virtual onlyRole(ADMIN_ROLE) returns(bool) {
    _grantRole(MANAGER_ROLE, manager);
    return hasRole(MANAGER_ROLE, manager);
  }

  //modify `tokenURI` of `estateContract` & `tokenId` accessible only manager
  function modifyProxyURI(address estateContract, uint256 tokenId, string memory newURI) public virtual override onlyRole(MANAGER_ROLE) whenNotPaused returns(bool){
    (bool success, ) = 
    estateContract.call(abi.encodeWithSelector(Estate.modifyTokenURI.selector, tokenId, newURI));
    require(success, "EstateFactory: modify URI failed");
    return  success;
  }

  //modify tokenMetadata of `estateContract` & `tokenId` accessible only manager
  function modifyProxyMetadata(address estateContract, uint256 tokenId, string memory newName, string memory newSymbol) public virtual override onlyRole(MANAGER_ROLE) whenNotPaused returns(bool) {
    (bool success, ) = 
    estateContract.call(abi.encodeWithSelector(Estate.modifyTokenMetadata.selector, tokenId, newName, newSymbol));
    require(success, "EstateFactory: modify metadata failed");
    return success;
  }

  //returns all estates listed to `safeAddress`
  function allSafeEstates(address safeAddress) external view virtual override returns(address[] memory) {
    return safeEstates[safeAddress];
  }

  //upgradeable beacon address
  function getEstateBeacon() external view virtual returns(address) {
    return estateBeacon;
  }

  //returns all addresses of proxies 
  function allProxies() external view virtual override returns(address[] memory) {
    return proxies;
  }

  //reurns total estates proxies 
  function proxiesCount() external view virtual override returns(uint256) {
    return proxies.length;
  }

  //returns estate contract address 
  function proxyAddrById(uint256 num) external view override returns(address) {
    return proxies[num];
  }

  //checks if taxId has been used before 
  function taxIdExists(uint256 taxId) public view returns(bool) {
    return existing[taxId];
  }

  //pause ops in factory and impl. accessible by upgrader only
  function emergencyPause() external virtual override onlyRole(UPGRADER_ROLE) {
    _pause();
  }

  //unpause ops in factory and impl. accessible by upgrader only
  function emergencyUnpause() external virtual override onlyRole(UPGRADER_ROLE) {
    _unpause();
  }

  //returns true if pause & false if not puased
  function isPaused() public view virtual override returns(bool) {
    return paused();
  }

}