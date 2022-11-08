// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IERC165Upgradeable.sol";

interface IERC1155Modified is IERC165Upgradeable {

    event Transfer(
        address indexed operator, 
        address indexed from, 
        address indexed to, 
        uint256 id, 
        uint256 value
    );

    event FailedTransfer(address operator, address from, address to, uint256 id);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    event VerifiableSet(address indexed verifiable, uint256 tokenId);

    function __VCToken_init(address upgrader) external;

    function setMinter(address verifiable, uint256 tokenId) external returns(uint256);

    function getNonce(address signer) external view returns(uint256);

    function totalSupply(uint256 id) external view returns(uint256);

    function exists(uint256 id) external view returns(bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function uri(uint256 id) external view returns (string memory);

    function name() external pure returns(string memory);

    function symbol() external pure returns(string memory);

    function authToken(address account) external view returns(uint256);

    function isVerified(address holder) external view returns(bool);

    function mint(address to, uint256 id, bytes memory signature) external returns(bool);

    function burn(address from, uint256 id, bytes memory signature) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}