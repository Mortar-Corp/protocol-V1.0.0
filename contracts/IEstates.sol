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

    function modifyTokenURI(uint256 tokenId, string memory uri) external;

    function changeMetadata(uint256 tokenId, string calldata name, string calldata symbol) external;

    function burn(uint256 tokenId) external;
}