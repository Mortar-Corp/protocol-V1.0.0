//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./MinterManager.sol";
import "./token/ERC20Upgradeable.sol";
import "./proxy/Initializable.sol";
import "./security/PausableUpgradeable.sol";
import "./proxy/UUPSUpgradeable.sol";
import "./utils/AddressUpgradeable.sol";
import "./interfaces/IERC1155Modified.sol";
import "./interfaces/IAmpersand.sol";
import "./security/ReentrancyGuardUpgradeable.sol";


contract Ampersand is 
    Initializable,
    IApmersand,
    MinterManager,
    ERC20Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
 {

    using AddressUpgradeable for address;

    mapping(address => uint256) private mintAllowances;
  

    string private constant _name = "Ampersand";
    string private constant _symbol = "AND";

    address private constant VCT = 0xd9145CCE52D386f254917e481eB44e9943F39138;



    function __Ampersand_init() public virtual override initializer {
        __ERC20_init("Ampersand", "AND");
        __MinterManager_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    function setAllowance(address minter, uint256 allowance) public virtual override onlyManager(msg.sender, minter) whenNotPaused {
        require(allowance > 0, "zero allowance");
        mintAllowances[minter] = allowance;
        emit MintAllowance(msg.sender, minter, allowance);
    }

    function increaseMintAllowance(address minter, uint256 increase) public virtual override onlyManager(msg.sender, minter) whenNotPaused {
        require(increase > 0, "new allowance is zero");
        uint256 oldAllowance = mintAllowances[minter];
        uint256 allowance = oldAllowance + increase;
        mintAllowances[minter] = allowance;
        emit AllowanceIncreased(msg.sender, minter, increase, allowance);
    }

    function decareseMinterAllowance(address minter, uint256 decrease) public virtual override onlyManager(msg.sender, minter) whenNotPaused {
        require(decrease > 0, "decrement is zero");
        uint256 currentAllowance = mintAllowances[minter];
        if(currentAllowance >= decrease) {
            uint256 allowance = currentAllowance - decrease;
            mintAllowances[minter] = allowance;
            emit AllowanceDecreased(msg.sender, minter, decrease, allowance);
        } else {
            revert("current allowance less than decreasing value");
        }
    }

    function mint(address safe, uint256 amount) public virtual override nonReentrant {
        require(AddressUpgradeable.isContract(safe), "safe is not contract");
        require(safe != address(0), "safe is zero address");
        //require(IERC1155Modified(VCT).isVerified(msg.sender), "Ampersand: unverified account");
        require(isMinter(msg.sender), "Ampersand: unauthorized minter");
        uint256 toMint = mintAllowances[msg.sender];
        require(toMint == amount, "Ampersand: mint exact allowance");
        unchecked {
            mintAllowances[msg.sender] = toMint - amount;
        }
        _mint(safe, amount);
        emit Mint(msg.sender, safe, amount);
    }

    function minterAllowance(address minter) external view virtual override returns(uint256) {
        return mintAllowances[minter];
    }

    function removeMinter(address minter) public virtual override onlyOwner whenNotPaused returns(bool) {
        require(isMinter(minter), "Ampersand: minter doesnot exist");
        exists[minter] = false;
        emit MinterRemoved(msg.sender, minter);
        return isMinter(minter);
    }

    function burn(address from, uint256 amount) public virtual override onlyOwner {
        require(amount > 0, "nothing to burn");
        _burn(from, amount);
        emit Burn(msg.sender, from, amount);
    }

    function pauseOps() public virtual override onlyOwner{
        _pause();
    }

    function unpauseOps() public virtual override onlyOwner {
        _unpause();
    } 

    function isPaused() public view virtual override returns(bool) {
       return paused();
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