//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IVault {


    event SaleInit(uint256 syndicated, uint256 minBuy);

    event SoldFractions(address indexed buyer, uint256 value);

    event MetadataChanged(string name, string symbol);

    event InvitationSend(address[] invitees, uint256 count);

    event NftUnwrapped(address indexed sendTo, uint256 nftId);


    function __Vault_init
    (
        address nftAddress, 
        uint256 nftId, 
        uint256 price,
        uint256 supply,
        string memory name, 
        string memory symbol, 
        address safe, 
        address nftOwner
    ) external;

    function changeMetadata(string memory name, string memory symbol) external;

    function invite(address[] memory _invitees) external;

    function openSale(uint8 syndicate, uint256 minToBuy) external;

    function TokenId() external view returns(uint256);

    function assetAddress() external view returns(address);

    function pricePerShare() external view returns(uint256);

    function buyFractions(address safe, uint256 shares) external;

    function unwrapNft(address to) external;

    function allBuyers() external view returns(address[] memory);

    function totalBuyers() external view returns(uint256);

    function buyerAddress(uint256 id) external view returns(address);

    function availFractions() external view returns(uint256);
}