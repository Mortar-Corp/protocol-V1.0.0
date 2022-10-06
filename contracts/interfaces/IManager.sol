//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IManager {

    //emitted when `callerAddress` modify tokenURI of `tokenId` to `newURI`
    event TokenURIModified(uint256 indexed tokenId, string newURI, address caller);
    //emitted when `tokenId` change metadata to `newName` & `newSymbol`
    event MetadataChanged(uint256 indexed tokenId, string newName, string newSymbol);

    function modifyTokenURI(uint256 tokenId, string memory uri) external;

    function modifyTokenMetadata(uint256 tokenId, string calldata name, string calldata symbol) external;

}