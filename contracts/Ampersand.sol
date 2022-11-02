//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./token/ERC20Upgradeable.sol";
import "./proxy/Initializable.sol";
import "./security/PausableUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./proxy/UUPSUpgradeable.sol";
import "./utils/AddressUpgradeable.sol";

contract Ampersand is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using AddressUpgradeable for address;


    mapping(address => uint256) private mintAllowances;
    mapping(address => bool) private minted;
    mapping(address => bool) private isManager;
    uint256 private totalManagers;
    string private constant _name = "Ampersand";
    string private constant _symbol = "AND";

    event ManagerSet(address indexed manager, uint256 count);
    event ManagerRemoved(address manager);
    event MintAllowance(address indexed caller, address minter, uint256 amount);

    function __Ampersand_init() public virtual initializer {
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    function setManager(address manager) public virtual onlyOwner {
        require(manager != address(0), "zero address");
        require(!_isManager(manager), "duplicate manager");
        isManager[manager] = true;
        totalManagers ++;
        emit ManagerSet(manager, totalManagers);
    }

    function removeManager(address manager) public virtual onlyOwner {
        require(_isManager(manager), "manager doesnot exist");
        isManager[manager] = false;
        totalManagers --;
        emit ManagerRemoved(manager);
    }

    function setMinter(address minter, uint256 amount) public virtual {
        require(msg.sender == owner() || _isManager(msg.sender), "neither owner nor manager");
        mintAllowances[minter] = amount;
        emit MintAllowance(msg.sender, minter, amount);
    }

    function mint(address safe, uint256 amount) public virtual {
        require(AddressUpgradeable.isContract(safe) && safe != address(0), "safe is not contract or zero address");
        require(minted[msg.sender] == false, "minted allowance");
        require(mintAllowances[msg.sender] == amount, "either caller or amount is wrong");
        minted[msg.sender] = true;
        _mint(safe, amount);
    }

    function minterAllowance(address minter) external view virtual returns(uint256) {
        return mintAllowances[minter];
    }

    function burn(uint256 amount) public virtual onlyOwner {
        require(amount > 0, "nothing to burn");
        _burn(address(this), amount);
    }

    function managersCount() external view virtual returns(uint256) {
        return totalManagers;
    }

    function name() public view virtual override returns(string memory){
        return _name;
    }

    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    function pauseOps() public virtual onlyOwner{
        _pause();
    }

    function unpauseOps() public virtual onlyOwner {
        _unpause();
    } 

    function isPaused() public view virtual returns(bool) {
       return paused();
    }

    function _isManager(address manager) public view virtual returns(bool) {
        return isManager[manager];
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "token transfer paused");
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual override {
        super._approve(owner, spender, amount);
        require(!paused(), "approvals paused");
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
        require(AddressUpgradeable.isContract(newImplementation), "new Implementation must be a contract");
        require(newImplementation != address(0), "zero address error");
    }

}