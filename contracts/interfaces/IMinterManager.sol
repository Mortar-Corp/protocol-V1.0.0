//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IMinterManager {

    event ManagerAssigned(address indexed manager, address indexed minter, uint256 minterId);
    
    event ManagerChanged(address oldManager, address indexed newManager);

    function assignManager(address minter, address manager) external returns(bool);

    function changeManager(address newManager, address prevManager, address minter, uint256 _index) external;

    function isManager(address manager, address minter) external view returns(bool);

    function allManagerMinters(address manager) external view returns(address[] memory);

    function managerMintersCount(address manager) external view returns(uint256);

    function minterAddress(address manager, uint256 id) external view returns(address);

    function isMinter(address minter) external view returns(bool);
}