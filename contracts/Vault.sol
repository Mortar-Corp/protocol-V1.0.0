//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./token/ERC721HolderUpgradeable.sol";
import "./interfaces/IERC721Modified.sol";
import "./token/ERC20Upgradeable.sol";
import "./proxy/Initializable.sol";
import "./interfaces/IVaultFactory.sol";
import "./access/OwnableUpgradeable.sol";
import "./token/SafeERC20Upgradeable.sol";
import "./interfaces/IERC20Upgradeable.sol";
import "./utils/AddressUpgradeable.sol";
import "./interfaces/IERC1155Modified.sol";
import "./interfaces/IVault.sol";

contract Vault is Initializable, OwnableUpgradeable, IVault, ERC721HolderUpgradeable, ERC20Upgradeable {

    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // nft owner variables
    address private _nftAddress;
    uint256 private _nftId;
    uint256 private sharePrice;
    uint256 private _supply;
    address private seller;
    address private nftSafe;
   
    enum Sale {inactive, active, ended}
    Sale saleState;

    //invitees
    mapping(address => bool) private invited;
    
    // fraction owners
    address[] buyers;
    uint256 private buyersCount;
    uint256 minBuy;

    // contracts storage
    IVaultFactory private factory;
    IERC20Upgradeable private AND;
    address private constant VCT = 0xf8e81D47203A594245E36C48e151709F0C19fBe8;
                            
    
    modifier onlySeller() {
        require(msg.sender == seller, "Vault: only seller");
        _;
    }

    function __Vault_init
    (
        address nftAddress, 
        uint256 nftId, 
        uint256 price,
        uint256 supply,
        string memory name_, 
        string memory symbol_, 
        address safe, 
        address nftOwner
    ) public virtual override initializer {
        __ERC20_init(name_, symbol_); 
        __ERC721Holder_init();
        __Ownable_init();

        factory = IVaultFactory(msg.sender);
        require(msg.sender != address(0), "Vault: factory is zero address");

        sharePrice = price / supply;

        AND = IERC20Upgradeable(0xaE036c65C649172b43ef7156b009c6221B596B8b);
        bool success = AND.approve(address(this), (sharePrice * supply));
        require(success, "Vault: unsuccessful approval");
        
        nftSafe = safe;
        seller = nftOwner;
        _nftAddress = nftAddress;
        _nftId = nftId;
        saleState = Sale.inactive;     
    }

    function changeMetadata(string memory name, string memory symbol) public virtual override {
        _ifNotPaused;
        require(msg.sender == owner(), "Vault: only mortar is authorized");
        require(saleState != Sale.active,"Vault: sale is active");
        _modifyMetadata(name, symbol);
        emit MetadataChanged(name, symbol);
    }

    function saleStatus() external view returns(Sale) {
        return saleState;
    }

    // seller invite investors which can buy shares when `openSale`
    // non zero addresses , no duplicated addresses
    function invite(address[] memory _invitees) public virtual override onlySeller {
        require(saleState == Sale.inactive, "Vault: sale is active");
        for(uint256 i = 0; i < _invitees.length; i ++) {
            address invitee = _invitees[i];
            require(invitee != address(0), "Vault: zero address");
            require(!_isInvited(invitee), "Vault: duplicate address");
            invited[invitee] = true;
        }
        uint256 count = _invitees.length;
        emit InvitationSend(_invitees, count);
    }

    //syndicate is no of shares of `totalSupply` minted directly to seller safe 
    //max syndication 40% of total supply
    //minToBuy: is min shares to purchase - not price but shares
    function openSale(uint256 syndicate, uint256 minToBuy) public virtual override onlySeller {
        _ifNotPaused;
        require(saleState == Sale.inactive, "Vault: sale is active or closed");
        require(IERC721Modified(_nftAddress).ownerOf(_nftId) == address(this), "Vault: token not recieved");
        
        uint256 max = _supply * 2 / 5;
        require(syndicate < max, "Vault: max syndication less than 40% of shares");
        
        uint256 sell = _supply - syndicate;        
        minBuy = minToBuy;
        require(minToBuy > 0 && minToBuy < sell, "Vault: min purchase more than 0 less than available");
        
        _mint(nftSafe, syndicate);
        _mint(address(this), sell);
        
        saleState = Sale.active;
        emit SaleInit(block.timestamp, syndicate, sell, minToBuy);
    }

    function TokenId() external view virtual override returns(uint256) {
        return _nftId;
    }

    function assetAddress() external view virtual override returns(address) {
        return _nftAddress;
    }

    // `shares` equal to or greater than `minToBuy` 
    // & less than or equaol to `availFractions`
    // to approve `AND` for shares * sharePrice = allowance.
    // accessible by invitation & to VCT holders only
    // transfer `AND` from buyer safe to this contract, then to seller safe.
    function buyFractions(address safe, uint256 shares) public virtual override {
        _ifNotPaused;
        require(saleState == Sale.active, "Vault: sale is not active");
        require(
            AddressUpgradeable.isContract(safe) && safe != address(0), 
            "Vault: safe is not contract or zero address"
        );
        require(
            IERC1155Modified(VCT).isVerified(msg.sender),
            "EstateFactory: verified holders only"
        );
        require(_isInvited(msg.sender), "Vault: missing invitation");
        require(shares <= availFractions() && shares >= minBuy, "Vault: zero amount or exceeds available fractions");

        uint256 sharesPrice = shares * sharePrice;
        if(sharesPrice <= AND.allowance(safe, address(this))) {
            AND.safeTransferFrom(safe, address(this), sharesPrice);
            AND.safeTransfer(nftSafe, sharesPrice);
            _transfer(address(this), safe, shares);
            emit SoldFractions(msg.sender, shares);
        } else {
            revert("Vault: insufficient ampersand allowance");
        }
        
        buyers.push(msg.sender);
        buyersCount = buyers.length;

        if(balanceOf(address(this)) == 0) {
            saleState = Sale.ended;
        } else {
            saleState = Sale.active;
        }

        emit SoldFractions(msg.sender, shares);
    }

    function pricePerShare() external view virtual override returns(uint256) {
        return sharePrice;
    }

    function allBuyers() external view virtual override returns(address[] memory) {
        return buyers;
    }

    function totalBuyers() external view virtual override returns(uint256) {
        return buyersCount;
    }

    function buyerAddress(uint256 id) external view virtual override returns(address) {
        return buyers[id];
    }

    function availFractions() public view override returns(uint256) {
        return balanceOf(address(this));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!factory.isOpsPaused(), "Vault: token transfer is paused");
    }

    function _ifNotPaused() private view returns(bool) {
        require(!factory.isOpsPaused(), "Vault: operations paused");
        return factory.isOpsPaused();
    }

    function _isInvited(address invitee) private view returns(bool) {
        return invited[invitee];
    }

}
