//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./proxy/Initializable.sol";
import "./tokens/IERC721Upgradeable.sol";
import "./tokens/IERC721ReceiverUpgradeable.sol";
import "./utils/ERC165Upgradeable.sol";
import "./utils/ContextUpgradeable.sol";
import "./utils/StringsUpgradeable.sol";
import "./utils/AddressUpgradeable.sol";
import "./security/ReentrancyGuardUpgradeable.sol";
import "./IEstates.sol";
import "./IEstatesFactory.sol";


/**
 *@title Estates
 *@author Sasha Flores
 *@dev This contract inherits from OZ ERC721 with other security contracts
 * this version is designed on semi-decentralized deployment design pattern
 * which grants Mortar Blockchain the right to manage token held in this contract.
 */

contract Estates is 
   Initializable, 
   ContextUpgradeable, 
   ERC165Upgradeable, 
   IERC721Upgradeable, 
   IEstates,
   ReentrancyGuardUpgradeable 
 {

   using StringsUpgradeable for uint256;
   using AddressUpgradeable for address;




   IEstatesFactory private Factory;
   uint256 private estateTokenId;
   address private _estateOwner;

   mapping(uint256 => address) private _owners;
   mapping(address => uint256) private _balances;
   mapping(uint256 => string) private _tokenURIs;                          
   mapping(uint256 => address) private _tokenApprovals;                    
   mapping(address => mapping(address => bool)) private _operatorApprovals;                    
   mapping(uint256 => bool) existing;
   mapping(uint256 => mapping(address => Estate)) private estateOwners;

                                 

   struct Estate {
      uint256 taxIdNo;
      string state;
      string city;
      uint256 zipcode;
      string tokenName;
      string tokenSymbol;
   }

   /**
    *@param estateOwner address, is the address of property owner.
    *@param estateManager address, is the address of mortar manager.
    */
   function __Estates_init(address estateManager, address estateOwner) public override initializer nonReentrant {

      __ReentrancyGuard_init();

      Factory = IEstatesFactory(msg.sender);
      require(msg.sender != address(0), "Estate: Factory is address zero");
      //_transferManagementContract(estateManager);

      _estateOwner = estateOwner;
      
      emit EstateInit(estateManager, estateOwner);
   }

   /**
    *@dev this function grants the estate owner the right to choose all
    * desired parameters mentioned below and the right to mint his token
    * with preserving the right of changing token credentials to mortar
    *
    *@param tokenName string, token name given by property owner
    *@param tokenSymbol string, token symbol given by property owner
    *@param estateURI string, property URI
    *@param taxIdNo uint, the property tax identification number
    *@param state string, state where property is located
    *@param city string, city where property is located
    *@param zipcode string, where property is located
    *
    * Requirements:
    * `estateOwner` only can mint the token 
    * each `taxIdNo` can only be used once to mint a token per property
    */

   function mintEstateToken
   (
      string memory tokenName, 
      string memory tokenSymbol, 
      string memory estateURI, 
      uint256 taxIdNo, 
      string memory state, 
      string memory city, 
      uint256 zipcode
   ) public virtual override nonReentrant returns(uint) {
      require(msg.sender == _estateOwner, "Estates: not owner");
      require(!existing[taxIdNo], "Estates: duplicate tax id no");
      existing[taxIdNo] = true;
      estateTokenId = Factory.proxiesCount();

      _safeMint(address(this), estateTokenId);
      _setTokenURI(estateTokenId, estateURI);
      

      estateOwners[estateTokenId][_estateOwner].tokenName = tokenName;
      estateOwners[estateTokenId][_estateOwner].tokenSymbol = tokenSymbol;
      estateOwners[estateTokenId][_estateOwner].state = state;
      estateOwners[estateTokenId][_estateOwner].city = city;
      estateOwners[estateTokenId][_estateOwner].zipcode = zipcode;
      estateOwners[estateTokenId][_estateOwner].tokenName = tokenName;
      estateOwners[estateTokenId][_estateOwner].tokenSymbol = tokenSymbol;

      return estateTokenId;
   }

   //change `name` & `symbol` of `tokenId`
   //accessible by `estateManger` only
   //onlyEstateManager
   function changeMetadata(uint256 tokenId, string memory name, string memory symbol) public virtual override  {
      Estate storage estate = estateOwners[tokenId][_estateOwner];
      estate.tokenName = name;
      estate.tokenSymbol = symbol;

      emit MetadataChanged(tokenId, name, symbol);
   }

   //returns `name` & `symbol` of `tokenId`
   function tokenMetadata(uint256 tokenId) public view virtual override returns(string memory, string memory) {
      return (estateOwners[tokenId][_estateOwner].tokenName, estateOwners[tokenId][_estateOwner].tokenSymbol);
   }

   //returns `tokenURI` of `tokenId`
   function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
      _requireMinting(tokenId);
      require(_exists(tokenId), "Estates: token donot exist"); 
      return _tokenURIs[tokenId];
   }

   //returns `state`, `city`, `zipcode` of `tokenId`
   function estateLocation(uint256 tokenId) public view virtual override returns(string memory, string memory, uint256) {
      return (estateOwners[tokenId][_estateOwner].state, estateOwners[tokenId][_estateOwner].city, estateOwners[tokenId][_estateOwner].zipcode);
   }

   //returns `taxIdNo` of `tokenId`
   function estateTaxIdNum(uint256 tokenId) external view virtual override returns(uint256) {
      return estateOwners[tokenId][_estateOwner].taxIdNo;
   }

   //`estateManger` only can transfer `tokenId` to `to` address
   //onlyEstateManager
   function transferToken(uint256 tokenId, address to) public virtual override nonReentrant {
      _transfer(address(this), to, tokenId);
   }

   //returns total supply of tokens
   function totalSupply() public view virtual override returns(uint256) {
      return estateTokenId;
   }

   //`estateManger` only can modify `URI` of `tokenId`
   //onlyEstateManager
   function modifyTokenURI(uint256 tokenId, string memory uri) public virtual override  {
      _setTokenURI(tokenId, uri);

      emit TokenURIModified(tokenId, uri, _msgSender());
   }

   //returns balance of `owner` address
   function balanceOf(address owner) public view virtual override returns(uint256) {
      require(owner != address(0), "Estates: owner can not be address zero");
      return _balances[owner];
   }

   //returns owner address of `tokenId`
   function ownerOf(uint256 tokenId) public view virtual override returns(address) {
      address owner = _owners[tokenId];
      require(owner != address(0), "ERC721: invalid token ID");
      return owner;
   }
   

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
    return 
    interfaceId == type(IERC721Upgradeable).interfaceId ||
    interfaceId == type(IEstates).interfaceId ||
    interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||

    super.supportsInterface(interfaceId);
  }

   //`estateManger` only can burn `tokenId`
   //onlyEstateManager
   function burn(uint256 tokenId) public virtual  {
      delete estateOwners[tokenId][_estateOwner];
      _burn(tokenId);
      emit Burnedtoken(tokenId, _msgSender());
   }

   //approve `to` address as an operator of `tokenId`
   function approve(address to, uint256 tokenId) public virtual override {
      address owner = Estates.ownerOf(tokenId);
      require(to != owner, "Estates: to can not be the owner");
      require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "Estates: caller should be owner or approved");
      _approve(to, tokenId);
   }

   //returns address been approved as an operator of `tokenId`
   function getApproved(uint256 tokenId) public view virtual override returns(address) {
      _requireMinting(tokenId);
      return _tokenApprovals[tokenId];
   }

   //set `operator` address to be `approved` on all owner tokens
   function setApprovalForAll(address operator, bool approved) public virtual override {
      _setApprovalForAll(_msgSender(), operator, approved);
   }

   //returns if `owner` of token approves `operator` or not
   function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
      return _operatorApprovals[owner][operator];
   }

   // transfer `tokenId` from `from` address to `to` address
   function transferFrom(address from, address to, uint256 tokenId) public virtual override {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "Estates: neither owner nor approved");
      _transfer(from, to, tokenId);
   }

   //safely transfer `tokenId` from `from` address to `to` address
   function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
      safeTransferFrom(from, to, tokenId, "");
   }

   // safely transfer `_data` of `tokenId` from `from` address to `to` address
   function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "Estates: neither owner nor approved");
      _safeTransferFrom(from, to, tokenId, _data);
   }

   //returns version of this contract
   function version() public pure virtual returns(string memory) {
      return "V1.0.0";
   }


   function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
     require(_exists(tokenId), "Estates: token donot exist"); 
      _tokenURIs[tokenId] = _tokenURI;
   }

   function _requireMinting(uint256 tokenId) internal view virtual {
      require(_exists(tokenId), "Estates: mint token first");
   }

   function _exists(uint256 tokenId) internal view virtual returns(bool) {
      return _owners[tokenId] != address(0);
   }

   function _safeMint(address to, uint256 tokenId) internal virtual {
      _safeMint(to, tokenId, "");
   }

   function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
      _mint(to, tokenId);
      require(_checkOnERC721Received(address(0), to, tokenId, _data),"Estates: transfer to non ERC721Receiver implementer");
   }

   function _mint(address to, uint256 tokenId) internal virtual {
      require(to != address(0), "Estates: mint to the zero address");
      require(!_exists(tokenId), "Estates: token already minted");
   
      _balances[to] += 1;
      _owners[tokenId] = to;
     
      emit Transfer(address(0), to, tokenId);
   }


   function _burn(uint256 tokenId) internal virtual {
      address owner = Estates.ownerOf(tokenId);
    
      _approve(address(0), tokenId);
 
      _balances[owner] -= 1;
      delete _owners[tokenId];

      if(bytes(_tokenURIs[tokenId]).length != 0) {
         delete _tokenURIs[tokenId];
      }

      emit Transfer(owner, address(0), tokenId);
   }

   function _approve(address to, uint256 tokenId) internal virtual {
      _tokenApprovals[tokenId] = to;
      emit Approval(Estates.ownerOf(tokenId), to, tokenId);
   }

   function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
      require(owner != operator, "Estates: approve to caller");
      _operatorApprovals[owner][operator] = approved;
      emit ApprovalForAll(owner, operator, approved);
   }

   function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
      require(_exists(tokenId), "Estates: token does not exist");
      address owner = Estates.ownerOf(tokenId);
      return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
   }

   function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
      _transfer(from, to, tokenId);
      require(_checkOnERC721Received(from, to, tokenId, _data), "Estates: transfer to non ERC721Receiver implementer");
   }

   function _transfer(address from, address to, uint256 tokenId) internal virtual {
      require(Estates.ownerOf(tokenId) == from, "Estates: transfer from incorrect owner");
      require(to != address(0), "Estates: transfer to the zero address");
      require(from != to, "Estates: transfer to self");

      _approve(address(0), tokenId);

      _balances[from] -= 1;
      _balances[to] += 1;
      _owners[tokenId] = to;

      emit Transfer(from, to, tokenId);
   }

   function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
      if (to.isContract()) {
         try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
         } catch (bytes memory reason) {
            if (reason.length == 0) {
               revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
               assembly {
                  revert(add(32, reason), mload(reason))
               }
            }
         }
      } else {
         return true;
      }
   }

 }