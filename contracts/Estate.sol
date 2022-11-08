//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./proxy/Initializable.sol";
import "./interfaces/IERC721Modified.sol";
import "./interfaces/IERC721ReceiverUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./utils/ERC165Upgradeable.sol";
import "./utils/StringsUpgradeable.sol";
import "./utils/AddressUpgradeable.sol";
import "./security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IEstateFactory.sol";
import "./interfaces/IManager.sol";



/**
 *@title Estate
 *@author Sasha Flores
 *@dev This contract inherits from OZ ERC721 with other security contracts
 * this version is designed on semi-decentralized deployment design pattern
 * which grants Mortar Blockchain the right to manage token held in this contract.
 */

contract Estate is 
   Initializable, 
   OwnableUpgradeable,
   ERC165Upgradeable, 
   IERC721Modified, 
   IManager,
   ReentrancyGuardUpgradeable 
 {

   using StringsUpgradeable for uint256;
   using AddressUpgradeable for address;


   IEstateFactory private factory;
   uint256 private _tokenId;
   address private _safeAddress;
   address private _owner;
   uint256 private _taxId;
   bool private minted = false;
   


   mapping(uint256 => address) private _owners;
   mapping(address => uint256) private _balances;
   mapping(uint256 => string) private _tokenURIs;                          
   mapping(uint256 => address) private _tokenApprovals;                    
   mapping(address => mapping(address => bool)) private _operatorApprovals;                    
   mapping(uint256 => mapping(address => Entity)) private estates;

                                 
   struct Entity {
      string state;
      string city;
      uint256 zipcode;
      string tokenName;
      string tokenSymbol;
      string tokenURI;
   }


   function __Estate_init(
      address safeAddress, 
      address owner, 
      uint256 taxId
   ) public payable override initializer nonReentrant {
      __Ownable_init();
      __ReentrancyGuard_init();

      _safeAddress = safeAddress;
      _taxId = taxId;
      _owner = owner;

      factory = IEstateFactory(msg.sender);
      require(msg.sender != address(0), "Estate: Factory is address zero");
   }

   function mintEstateToken
   (
      string memory state, 
      string memory city, 
      uint256 zipcode,
      string memory tokenName, 
      string memory tokenSymbol, 
      string memory tokenURI
   ) public virtual override onlyOwner nonReentrant returns(uint) {
      require(minted == false, "Estate: estate token minted");
      _tokenId = factory.proxiesCount();
      _safeMint(_safeAddress, _tokenId);
      _setTokenURI(_tokenId, tokenURI);
      minted = true;
      estates[_tokenId][msg.sender] = Entity(state, city, zipcode, tokenName, tokenSymbol, tokenURI);
      
      return _tokenId;
   }

   function isPaused() public view returns(bool) {
      return factory.isPaused();
   }


   //change `name` & `symbol` of `tokenId`
   //accessible by `estateManger` only
   function modifyTokenMetadata(uint256 tokenId, string memory name, string memory symbol) public virtual override{
      _notPaused();
      require(_msgSender() == address(factory), "Estate: unauthorized call");
      Entity storage entity = estates[tokenId][_owner];
      entity.tokenName = name;
      entity.tokenSymbol = symbol;

      emit MetadataChanged(tokenId, name, symbol);
   }

   //returns `name` & `symbol` of `tokenId`
   function tokenMetadata(uint256 tokenId) public view virtual override returns(string memory, string memory, string memory) {
      _requireMinting(tokenId);
      require(_exists(tokenId), "Estate: token donot exist"); 
      return (estates[tokenId][_owner].tokenName, estates[tokenId][_owner].tokenSymbol, _tokenURIs[tokenId]);
   }


   //returns `state`, `city`, `zipcode` of `tokenId`
   function estateLocation(uint256 tokenId) public view virtual override returns(string memory, string memory, uint256) {
      return (estates[tokenId][_owner].state, estates[tokenId][_owner].city, estates[tokenId][_owner].zipcode);
   }

   //returns total supply of tokens
   function totalSupply() public view virtual override returns(uint256) {
      return _tokenId;
   }


   function tokenTransfer(address to, uint256 tokenId) public onlyOwner {
      _transfer(_safeAddress, to, tokenId);
   }

   function modifyTokenURI(uint256 tokenId, string memory uri) public virtual override {
      _notPaused();
      require(_msgSender() == address(factory), "Estate: unauthorized call");
   
      _setTokenURI(tokenId, uri);
      emit TokenURIModified(tokenId, uri, msg.sender);
   }

   //returns balance of `owner` address
   function balanceOf(address owner) public view virtual override returns(uint256) {
      require(owner != address(0), "Estate: owner can not be address zero");
      return _balances[owner];
   }

   //returns owner address of `tokenId`
   function ownerOf(uint256 tokenId) public view virtual override returns(address) {
      address owner = _owners[tokenId];
      require(owner != address(0), "Estate: invalid token ID");
      return owner;
   }
   

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
    return 
    interfaceId == type(IERC721Modified).interfaceId ||
    interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
    interfaceId == type(IManager).interfaceId ||

    super.supportsInterface(interfaceId);
  }



   function burn(uint256 tokenId) public virtual override onlyOwner {
      _burn(tokenId);
      selfdestruct(payable(_owner));
   }

   //approve `to` address as an operator of `tokenId`
   function approve(address to, uint256 tokenId) public virtual override {
      _notPaused();
      address owner = Estate.ownerOf(tokenId);
      require(to != owner, "Estate: to can not be the owner");
      require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "Estate: caller should be owner or approved");
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
      require(_isApprovedOrOwner(_msgSender(), tokenId), "Estate: neither owner nor approved");
      _transfer(from, to, tokenId);
   }

   //safely transfer `tokenId` from `from` address to `to` address
   function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
      safeTransferFrom(from, to, tokenId, "");
   }

   // safely transfer `_data` of `tokenId` from `from` address to `to` address
   function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "Estate: neither owner nor approved");
      _safeTransferFrom(from, to, tokenId, _data);
   }

   //returns version of this contract
   function version() public pure virtual override returns(string memory) {
      return "V1.0.0";
   }

   function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
     require(_exists(tokenId), "Estate: token donot exist"); 
      _tokenURIs[tokenId] = _tokenURI;
   }

   function _requireMinting(uint256 tokenId) internal view virtual {
      require(_exists(tokenId), "Estate: mint token first");
   }


   function _exists(uint256 tokenId) internal view virtual returns(bool) {
      return _owners[tokenId] != address(0);
   }

   function _safeMint(address to, uint256 tokenId) internal virtual {
      _safeMint(to, tokenId, "");
   }

   function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
      _mint(to, tokenId);
      require(_checkOnERC721Received(address(0), to, tokenId, _data),"Estate: transfer to non ERC721Receiver implementer");
   }

   function _mint(address to, uint256 tokenId) internal virtual {
      _beforeTokenTransfer(address(0), to, tokenId);
   }


   function _burn(uint256 tokenId) internal virtual {
      _beforeTokenTransfer(Estate.ownerOf(tokenId), address(0), tokenId);
   }


   function _approve(address to, uint256 tokenId) internal virtual {
      _notPaused();
      _tokenApprovals[tokenId] = to;
      emit Approval(Estate.ownerOf(tokenId), to, tokenId);
   }

   function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
      _notPaused();
      require(owner != operator, "Estate: approve to caller");
      _operatorApprovals[owner][operator] = approved;
      emit ApprovalForAll(owner, operator, approved);
   }

   function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
      require(_exists(tokenId), "Estate: token does not exist");
      address owner = Estate.ownerOf(tokenId);
      return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
   }

   function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
      _transfer(from, to, tokenId);
      require(_checkOnERC721Received(from, to, tokenId, _data), "Estate: transfer to non ERC721Receiver implementer");
   }

   function _transfer(address from, address to, uint256 tokenId) internal virtual {
      _beforeTokenTransfer(from, to, tokenId);
   }

   function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
      _notPaused();
      // `_mint` function
      if(from == address(0) && to != address(0)) {
         require(!_exists(tokenId), "Estate: token already minted");
         unchecked {
            _balances[to] += 1;
         }
         _owners[tokenId] = to;
         emit Transfer(address(0), to, tokenId);
      } //`_burn` function
      else if(from != address(0) && to == address(0)) {
         address owner = Estate.ownerOf(tokenId);
         delete _tokenApprovals[tokenId];
         unchecked {
            _balances[owner] -= 1;
         }
         delete _owners[tokenId];
         if(bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
         }
         emit Transfer(owner, address(0), tokenId);
      } // `transfer` function
      else if(from != to) {
         require(Estate.ownerOf(tokenId) == from, "Estate: transfer from incorrect owner");
         require(to != address(0), "Estate: transfer to the zero address");
         delete _tokenApprovals[tokenId];
         unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
         }
         _owners[tokenId] = to;

         emit Transfer(from, to, tokenId);
      }
      else{
         revert("Estate: transfer failed");
      }
   }

   function _notPaused() private view {
      require(!factory.isPaused(), "Estate: operations paused");
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