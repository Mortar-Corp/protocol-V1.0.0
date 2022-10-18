//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IVault {


    event SaleInit(uint256 at);

    event SoldFractions(address indexed buyer, uint256 value);

    event MetadataChanged(string name, string symbol);

    event SaleClaimed(uint256 at, uint256 payment);

    function __Vault_init
    (
        address nftAddress, 
        uint256 tokenId, 
        string memory name, 
        string memory symbol, 
        uint256 askPrice, 
        address safe, 
        address nftOwner
    ) external;

    function changeMetadata(string memory name, string memory symbol) external;

    function openSale() external;

    function getPrice() external view returns(uint256);

    function TokenId() external view returns(uint256);

    function assetAddress() external view returns(address);

    function buyFractions(address safe, uint256 value) external payable;

    function claimPayment() external;

    function allBuyers() external view returns(address[] memory);

    function totalBuyers() external view returns(uint256);

    function buyerAddress(uint256 id) external view returns(address);

    function availFractions() external view returns(uint256);
}