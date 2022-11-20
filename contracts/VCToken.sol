//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


import "./proxy/Initializable.sol";
import "./proxy/UUPSUpgradeable.sol";
import "./access/AccessControlUpgradeable.sol";
import "./utils/ERC165Upgradeable.sol";
import "./utils/AddressUpgradeable.sol";
import "./cryptography/EIP712Upgradeable.sol";
import "./cryptography/SignatureCheckerUpgradeable.sol";
import "./interfaces/IERC1155Modified.sol";
import "./interfaces/IERC1155ReceiverUpgradeable.sol";
import "./utils/CountersUpgradeable.sol";
import "./security/PausableUpgradeable.sol";

/**
 *@title VCToken "Verified Cerdentials Token"
 *@author Sasha Flores
 *@notice allows US-based entities and individuals globally to mint VCToken
 * after being verified, so far supported tokens are five.
 * Mortar grants user "MINTER_ROLE" with deadline of 7 days to mint.
 * Requirements
 * - user is granted "MINTER_ROLE"
 * - deadline is 7 days
 * - Business Token should be minted to safe
 * - all other tokens should be minted to address
 * - only business token is transferable
 */

contract VCToken is 
    Initializable, 
    ERC165Upgradeable, 
    IERC1155Modified, 
    AccessControlUpgradeable, 
    EIP712Upgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;


    uint256[5] private availableIds;
    string private constant _uri = "http://bafybeihqp5dcnhnspwhs3fqh4tmzweu6nw33iukx6i4sqnv4vwed3zuwc4.ipfs.localhost:8080/{id}.json";
    string private constant _name = "VCToken";
    string private constant _symbol = "VCT";


    uint256 private start;
    uint256 private constant EXPIRY = 7 days;
    mapping(address => CountersUpgradeable.Counter) private nonces;
    mapping(address => bool) private minted;
    mapping(address => uint256) private _authToken;
    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 public constant BUSINESS = 1;
    uint256 public constant US_PERSON = 2;
    uint256 public constant INT_PERSON = 3;
    uint256 public constant US_ACCREDITED_INVESTOR = 4;
    uint256 public constant INT_ACCREDITED_INVESTOR = 5;

    bytes32 public constant ADMIN_ROLE = keccak256(abi.encodePacked("ADMIN_ROLE"));
    bytes32 public constant MINTER_ROLE = keccak256(abi.encodePacked("MINTER_ROLE"));
    bytes32 public constant UPGRADER_ROLE = keccak256(abi.encodePacked("UPGRADER_ROLE"));

    //keccak256("Mint(address to,uint256 id,uint256 nonce)");
    bytes32 private constant MINT_TYPEHASH = 0xa53b9b633e60c98d0ba266e3e9f0b79181e74b680a5998368333c1f15f06484a;

    //keccak256("Burn(address from,uint256 id,uint256 nonce)")
    bytes32 private constant BURN_TYPEHASH = 0x65ec0a3d9b23902e2fe999689a69e8e5ad5bcaab57b8635aec70eaae30d3d87f;

    

    function __VCToken_init(address upgrader) public virtual override initializer {
        __AccessControl_init();
        __Pausable_init();
        __EIP712_init("VCToken", "1.0.0");
        __UUPSUpgradeable_init();

        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(UPGRADER_ROLE, upgrader);
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

    /**
     * returns `tokenId` of each `minter` address
     * in case of business token inquiry, use safe address
     */
    function authToken(address account) public view virtual override returns(uint256) {
        return _authToken[account];
    }

    /**
     * returns true if address has been verified
     *  and `authToken` has been minted & false if not
     */
    function isVerified(address holder) public view virtual override returns(bool) {
        return minted[holder];

    }

    function pause() public virtual onlyRole(UPGRADER_ROLE) {
        _pause();
    }

    function unpause() public virtual onlyRole(UPGRADER_ROLE) {
        _unpause();
    }

    function isPaused() external view virtual returns(bool) {
        return paused();
    }

    /**
     * `ADMIN_ROLE` grants `MINTER_ROLE` to `signer` to mint & burn token 
     * starts the timer of 7 days to mint once `setMinter` is provoked
     */
    function setMinter(address verifiable, uint256 tokenId) public virtual override onlyRole(ADMIN_ROLE) whenNotPaused returns(uint256) {
        require(verifiable != address(0), "VCToken: non zero address only");
        require(tokenId <= availableIds.length, "VCToken: requested id unavailable");
        _authToken[verifiable] = tokenId;
        start = block.timestamp;
        _grantRole(MINTER_ROLE, verifiable);
        emit VerifiableSet(verifiable, tokenId);
        return tokenId;
    }

    // returns `nonce` of `signer`
    function getNonce(address signer) public view virtual override returns(uint256) {
        return nonces[signer].current();
    }

    /**
     * Requirements:
     * - has `MINTER_ROLE`
     * - if `id` is 1 `to` should be contract
     * - see {_mint}
     * - balance before mint is zero
     * - mint before deadline
     * see {_beforeTokenTransfer}
     */
    function mint(address to, uint256 id, bytes calldata signature) public virtual override returns(bool) {
        uint256 end = start + EXPIRY;
        require(block.timestamp < end, "VCToken: expired deadline");
        require(balanceOf(to, id) == 0, "VCToken: balance should be 0 before minting");
        require(_authToken[to] == id, "VCToken: wrong token id or address");
        
        address signer = msg.sender;
        bytes32 txHash = getMintHash(to, id, _incrementNonce(signer));
        require(verifySignature(signer, txHash, signature), "VCToken: invalid signature");

        _mint(to, id, 1, "");
        minted[to] = true;
       
        return minted[to];
    }

    /**
     * Requirements:
     * - has `MINTER_ROLE`
     * see {_beforeTokenTransfer}
     */
    function burn(address from, uint256 id, bytes calldata signature) public virtual override {
        address signer = msg.sender;
        bytes32 txHash = getBurnHash(from, id, _incrementNonce(signer));
        require(verifySignature(signer, txHash, signature), "VCToken: invalid signature");

        _burn(from, id, 1);
        _revokeRole(MINTER_ROLE, msg.sender);
        minted[from] = false;
    }

    
    function getMintHash(address safeAddr, uint256 id, uint256 _nonce) public view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MINT_TYPEHASH, safeAddr, id, _nonce)));
    }

    function getBurnHash(address from, uint256 id, uint256 _nonce) public view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(BURN_TYPEHASH, from, id, _nonce)));
    }

    function verifySignature(address signer, bytes32 txHash, bytes memory signature) public view returns(bool) {
        return hasRole(MINTER_ROLE, signer) && SignatureCheckerUpgradeable.isValidSignatureNow(signer, txHash, signature);
    }


    function _incrementNonce(address signer) internal virtual returns(uint256 current) {
        CountersUpgradeable.Counter storage nonce = nonces[signer];
        current = nonce.current();
        nonce.increment();
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

    function version() public pure returns(string memory) {
        return "1.0.0";
    }

    // retruns `balanceOf` of `id` in `account` 
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "VCToken: address zero is not a valid owner");
        return _balances[id][account];
    }

    // returns `totalSupply` of token `id`
    function totalSupply(uint256 id) public view override returns(uint256) {
        return _totalSupply[id];
    }

    // checks if token `id` has ever been minted 
    function exists(uint256 id) public view override returns(bool) {
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

    function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
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
        address operator = _msgSender();
        require(id <= availableIds.length, "VCToken: requested id unavailable");
        if(id == 1) {
            require(AddressUpgradeable.isContract(to), "VCToken: mint business to safe");
            require(isVerified(msg.sender), "VCToken: minter of business token isnot verified");
        } else{
            require(to == msg.sender, "VCT: mint to address only");
        }
        _beforeTokenTransfer(operator, address(0), to, id, amount, data);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {   
        require(exists(id), "VCToken: not minted");
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
        require(!paused(), "VCToken: operations paused");
        //mint
        if(from == address(0) && to != address(0)) {
            _balances[id][to] += amount;
            _totalSupply[id] += amount;
            emit Transfer(operator, address(0), to, id, amount);
        }
        //burn
        if(from !=address(0) && to == address(0)) {
            uint256 supply = _totalSupply[id];
            require(supply >= amount, "VCToken: burn amount exceeds total supply");
            _totalSupply[id] = supply - amount; 

            uint256 fromBal = _balances[id][from];
           require(fromBal >= amount, "VCToken: burn amount exceeds balance");
           _balances[id][from] = fromBal - amount;

           delete _authToken[from];

           emit Transfer(operator, from, address(0), id, amount);
        }
        //transfer
        if(from != address(0) && to != address(0)) { 
            if(id == 1) {
                uint256 fromBal = _balances[id][from];
                require(fromBal >= amount, "VCToken: transfer amount exceeds balance");
                _balances[id][from] = fromBal - amount;
                _balances[id][to] += amount;
                emit Transfer(operator, from, to, id, amount);
            } else {
                emit FailedTransfer(operator, from, to, id);
                revert("VCToken: only business transfer");
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

    /**
     * only `ADMIN_ROLE` is allowed to upgrade contract to next version
     * `newImplementation` should be a contract and non zero address
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {
    require(AddressUpgradeable.isContract(newImplementation), "VCToken: new Implementation must be a contract");
    require(newImplementation != address(0), "VCToken: set to zero address");
  }
}