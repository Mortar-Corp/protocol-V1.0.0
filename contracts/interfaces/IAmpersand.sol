//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IAmpersand {
    
    event MintAllowance(address indexed caller, address indexed minter, uint256 amount);
    event AllowanceIncreased(address indexed caller, address indexed minter, uint256 increasedby, uint256 newAllowance);
    event AllowanceDecreased(address indexed caller, address indexed minter, uint256 decreasedby, uint256 newAllowance);
    event Mint(address indexed executor, address to, uint256 amount);
    event Burn(address executor, address from, uint256 amount);
    event MinterRemoved(address caller, address minter);

    function __Ampersand_init() external;

    function setAllowance(address minter, uint256 allowance) external;

    function increaseMintAllowance(address minter, uint256 increase) external;

    function decareseMinterAllowance(address minter, uint256 decrease) external;

    function mint(address safe, uint256 amount) external;

    function minterAllowance(address minter) external view returns(uint256);

    function removeMinter(address minter) external returns(bool);

    function burn(address from, uint256 amount) external;

    function pauseOps() external;

    function unpauseOps() external;

    function isPaused() external view returns(bool);

}