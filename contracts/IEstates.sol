//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/** 
 *@title Estates contract interface
 *@author Sasha Flores
 *@dev this interface is designed to allow each estate to have a customized 
 * `tokenName` & `tokenSymbol` while granting mortar the right to modify these parameters
 * including `estateURI` to avoid duplication &/or adhere to legal requirements.
 */
interface IEstates {

    //emitted when `estateManager` & `estateOwner` is initiated
    event EstateInit(address indexed estateManager, address indexed estateOwner);

    //emitted when `callerAddress` modify tokenURI of `tokenId` to `newURI`
    event TokenURIModified(uint256 indexed tokenId, string newURI, address callerAddress);

    //emitted when `tokenId` change metadata to `newName` & `newSymbol`
    event MetadataChanged(uint256 indexed tokenId, string newName, string newSymbol);

    //emitted when `tokenId` is burned by `callerAddress`
    event Burnedtoken(uint256 tokenId, address callerAddress);

    function __Estates_init(address estateManager, address estateOwner) external;

    function tokenMetadata(uint256 tokenId) external view returns(string memory, string memory);

    function mintEstateToken
    (
        string memory tokenName, 
        string memory tokenSymbol, 
        string memory estateURI, 
        uint256 taxIdNo, 
        string memory state, 
        string memory city, 
        uint256 zipcode
    ) external returns(uint256);

    function tokenURI(uint256 estateTokenId) external view returns(string memory);

    function transferToken(uint256 tokenId, address to) external;

    function modifyTokenURI(uint256 tokenId, string memory uri) external;

    function totalSupply() external view returns(uint256);

    function changeMetadata(uint256 tokenId, string calldata name, string calldata symbol) external;

    function estateLocation(uint256 tokenId) external view returns(string memory, string memory, uint256);

    function burn(uint256 tokenId) external;

    function estateTaxIdNum(uint256 tokenId) external view returns(uint256);

}