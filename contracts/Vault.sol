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
    address private asset;
    uint256 private assetId;
    uint256 private price;
    address payable private seller;
    address private nftSafe;
   
    enum Sale {inactive, active, ended, claimed}
    Sale saleState;
    
    // fraction owners
    address[] buyers;
    uint256 private buyersCount;

    // contracts storage
    IVaultFactory private factory;
    IERC20Upgradeable private AND;
    address private constant VCT = 0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c;
    
    modifier onlySeller() {
        require(msg.sender == seller, "Vault: only seller");
        _;
    }

    function __Vault_init
    (
        address nftAddress, 
        uint256 tokenId, 
        string memory name, 
        string memory symbol, 
        uint256 askPrice, 
        address safe, 
        address nftOwner
    ) public virtual override initializer {
        __ERC20_init(name, symbol); 
        __ERC721Holder_init();
        __Ownable_init();

        factory = IVaultFactory(msg.sender);
        require(msg.sender != address(0), "Vault: factory is zero address");
        
        AND = IERC20Upgradeable(0xaE036c65C649172b43ef7156b009c6221B596B8b);
        bool success = AND.approve(address(this), askPrice);
        require(success, "Vault: unsuccessful approval");

        nftSafe = safe;
        seller = payable(nftOwner);
        price = askPrice;
        asset = nftAddress;
        assetId = tokenId;
        saleState = Sale.inactive;
        
    }

    function changeMetadata(string memory name, string memory symbol) public virtual override {
        _ifNotPaused;
        require(msg.sender == owner(), "Vault: only mortar is authorized");
        _name = name;
        _symbol = symbol;
        emit MetadataChanged(name, symbol);
    }

    function saleStatus() external view returns(Sale) {
        return saleState;
    }

    function openSale() public virtual override onlySeller {
        _ifNotPaused;
        require(saleState == Sale.inactive, "Vault: sale is active or closed");
        require(IERC721Modified(asset).ownerOf(assetId) == address(this), "Vault: token not recieved");
        _mint(address(this), price);
        saleState = Sale.active;
        emit SaleInit(block.timestamp);
    }

    function getPrice() external view virtual override returns(uint256) {
        return price;
    }

    function TokenId() external view virtual override returns(uint256) {
        return assetId;
    }

    function assetAddress() external view virtual override returns(address) {
        return asset;
    }

    function buyFractions(address safe, uint256 value) public payable virtual override {
        _ifNotPaused;
        require(saleState == Sale.active, "Vault: sale is not active");
        require(
            AddressUpgradeable.isContract(safe) && safe != address(0), 
            "Vault: safe is not contract or zero address"
        );
        require(
            IERC1155Modified(VCT).isVerified(safe) || 
            IERC1155Modified(VCT).isVerified(msg.sender),
            "EstateFactory: verified holders only"
        );
        require(value <= totalSupply() && value > 0, "Vault: zero amount or exceeds available fractions");
        if(value <= AND.allowance(safe, address(this))) {
            AND.safeTransferFrom(safe, address(this), value);
            _transfer(address(this), safe, value);
            emit SoldFractions(msg.sender, value);
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

        emit SoldFractions(msg.sender, value);
    }


    function claimPayment() public virtual override onlySeller {
        _ifNotPaused;
        require(saleState == Sale.ended, "Vault: sale is active");
        AND.safeTransfer(nftSafe, price);
        saleState = Sale.claimed;
        emit SaleClaimed(block.timestamp, price);
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

    function availFractions() external view override returns(uint256) {
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

}
