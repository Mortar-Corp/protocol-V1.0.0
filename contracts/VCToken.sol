//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "./IERC1155Modified.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract VCToken is 
    Initializable, 
    ERC165Upgradeable, 
    IERC1155Modified, 
    AccessControlUpgradeable, 
    EIP712Upgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private clientsCount;


    uint256[5] private availableIds;
    string private constant _uri = "www.sahe.com";
    string private constant _name = "VCToken";
    string private constant _symbol = "VCT";

    uint256 private nonce;
    uint256 private start;
    uint256 private constant EXPIRY = 7 days;
    mapping(address => CountersUpgradeable.Counter) private nonces;
    mapping(uint256 => address) private clientIds;


    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 public constant BUSINESS = 1;
    uint256 public constant US_PERSON = 2;
    uint256 public constant INT_PERSON = 3;
    uint256 public constant US_ACCREDITED_INVESTOR = 4;
    uint256 public constant INT_ACCREDITED_INVESTOR = 5;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 private constant MINT_TYPEHASH = keccak256("Mint(address to,uint256 id,uint256 nonce)");



    

    function __VCToken_init() public initializer {
        __AccessControl_init();
        __ERC165_init();
        __EIP712_init("VCToken", "1.0.0");
        __UUPSUpgradeable_init();

        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override
    (
        ERC165Upgradeable, 
        IERC165Upgradeable, 
        AccessControlUpgradeable
    ) returns (bool) 
    
    {
        return 
        interfaceId == type(IERC1155Modified).interfaceId ||
        interfaceId == type(AccessControlUpgradeable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function domainSeparator() public view returns(bytes32) {
        return _domainSeparatorV4();
    }

    function chainId() public view returns(uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function getClientAddress(uint256 clientId) public view returns(address) {
        return clientIds[clientId];
    }

    function setMinter(address signer) public virtual onlyRole(ADMIN_ROLE) returns(uint256) {
        require(signer != address(0), "non zero address only");
        clientsCount.increment();
        uint256 clientId = clientsCount.current();
        clientIds[clientId] = signer;
        start = block.timestamp;
        _grantRole(MINTER_ROLE, signer);
        return clientId;
    }

    function getNonce(address owner) public view returns(uint256) {
        return nonces[owner].current();
    }

    function mint(address to, uint256 id, bytes calldata signature) public {
        uint256 end = start + EXPIRY;
        require(block.timestamp < end, "expired deadline");
        //require(balanceOf(_msgSender(), id) == 0, "one token per address");
        require(to != address(0), "non zero address only");
        require(hasRole(MINTER_ROLE, to), "missing authorization");

        // bytes32 structHash = keccak256(abi.encodePacked(MINT_TYPEHASH, to, id, nonce));
        // bytes32 TxHash = _hashTypedDataV4(structHash);
        bytes32 txHash = getMintHash(to, id, nonce);
        if(id != 1){
            address signer = ECDSA.recover(txHash, signature);
            require(signer == to, "invalid signature");
        } else {
            bytes4 magicValue = IERC1271(to).isValidSignature(txHash, signature);
            require(magicValue == 0x1626ba7e, "business token should be minted to wallet address");
        }
        //nonce++;

        _mint(to, id, 1, "");
    }

    function getMintHash(address to, uint256 id, uint256 _nonce) public view returns(bytes32) {
        //nonce = nonces[to];
        bytes32 structHash = keccak256(abi.encode(MINT_TYPEHASH, to, id, _nonce));
        return _hashTypedDataV4(structHash);
    }

    function verifySiganture(address signer, bytes32 txHash, bytes memory signature) public view returns(bool) {
        return SignatureChecker.isValidSignatureNow(signer, txHash, signature);
    }

    // function _incrementNonce(address owner) internal virtual returns(uint256 current) {
    //     CountersUpgradeable.Counter storage nonce = nonces[owner];
    //     current = nonce.current();
    //     nonce.increment();
    // }


    function burn(address from, uint256 id) public  {
        _burn(from, id, 1);
    }

    function transfer(address from, address to, uint256 id) public {
        _safeTransferFrom(from, to, id, 1, "");
    }

    function name() public pure virtual override returns(string memory) {
        return _name;
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function symbol() public pure virtual override returns(string memory) {
        return _symbol;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "VCToken: address zero is not a valid owner");
        return _balances[id][account];
    }

    function totalSupply(uint256 id) public view returns(uint256) {
        return _totalSupply[id];
    }

    function minted(uint256 id) public view returns(bool) {
        return VCToken.totalSupply(id) > 0;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "VCToken: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

   function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, to, id, amount, data);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(id <= availableIds.length, "VCToken: requested id unavailable");
        address operator = _msgSender();     
        _beforeTokenTransfer(operator, address(0), to, id, amount, data);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {   
        require(minted(id), "VCToken: not minted");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, address(0), id, amount, "");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "VCToken: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256 id, 
        uint256 amount,
        bytes memory data
    ) internal virtual {
        
        if(from == address(0) && to != address(0)) {
            _balances[id][to] += amount;
            _totalSupply[id] += amount;
            emit Transfer(operator, address(0), to, id, amount);
        }
        if(from !=address(0) && to == address(0)) {
            uint256 supply = _totalSupply[id];
            require(supply >= amount, "VCToken: burn amount exceeds total supply");
            _totalSupply[id] = supply - amount; 

            uint256 fromBal = _balances[id][from];
           require(fromBal >= amount, "VCToken: burn amount exceeds balance");
           _balances[id][from] = fromBal - amount;

           emit Transfer(operator, from, address(0), id, amount);
        }
        if(from != address(0) && to != address(0)) { 
            if(id == 1) {
                uint256 fromBal = _balances[id][from];
                require(fromBal >= amount, "VCToken: transfer amount exceeds balance");
                _balances[id][from] = fromBal - amount;
                _balances[id][to] += amount;
                emit Transfer(operator, from, to, id, amount);
            } else {
                emit FailedTransfer(operator, from, to, id);
                revert("only business transfer");
            }
        } 
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(ADMIN_ROLE) {
    require(AddressUpgradeable.isContract(newImplementation), "NFT: new Implementation must be a contract");
    require(newImplementation != address(0), "NFT: set to zero address");
  }
}