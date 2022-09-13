// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 *@dev Inheriting this contract grants parent contract to assign `estateMananger` 
 * which will be the contract manager in parent contract and will have 
 * the power to transfer ownership of parent contract to a new manager,
 * estate owner, and/or any other address using `transferManagementContract`
 * function. This contract gives mortar the right to manage the digital representation
 * of the property on mortar chain.
 */

abstract contract Management is Initializable, ContextUpgradeable {
    address private _manager;

    event ManagementContractTransferred(address indexed OldContractManager, address indexed newContractManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    function __Management_init() internal onlyInitializing {
       _transferManagementContract(_msgSender());
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyEstateManager() {
        require(manager() == _msgSender(), "Management: caller has to be the estate manager");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newContractManager`).
     * Can only be called by the current manager.
     */
    function transferManagementContract(address newContractManager) public virtual onlyEstateManager {
        require(newContractManager != address(0), "Management: new manager is the zero address");
        _transferManagementContract(newContractManager);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newContractManager`).
     * Internal function without access restriction.
     */
    function _transferManagementContract(address newContractManager) internal virtual {
        address oldManager = _manager;
        _manager = newContractManager;
        emit ManagementContractTransferred(oldManager,newContractManager);
    }

}
