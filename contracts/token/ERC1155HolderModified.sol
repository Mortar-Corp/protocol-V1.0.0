// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../proxy/Initializable.sol";


contract ERC1155HolderModified is Initializable, ERC1155ReceiverUpgradeable {
    
    function __ERC1155HolderModified_init() internal onlyInitializing {
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}