// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC165Upgradeable.sol";


interface IERC721Modified is IERC165Upgradeable {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function __Estate_init(address safeAddress, address owner, uint256 taxId) external payable;

    function name(uint256 tokenId) external view returns(string memory);

    function symbol(uint256 tokenId) external view returns(string memory);

    function tokenUri(uint256 tokenId) external view returns(string memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mintEstateToken
    (
        string memory state, 
        string memory city, 
        uint256 zipcode,
        string memory tokenName, 
        string memory tokenSymbol, 
        string memory tokenURI
    ) external returns(uint256);

    function version() external pure returns(string memory);
    
    function totalSupply() external view returns(uint256);

    function estateLocation(uint256 tokenId) external view returns(string memory, string memory, uint256);


    function burn(uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
