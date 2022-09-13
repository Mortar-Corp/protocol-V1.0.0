//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

library AccountType {

    //can be tranferred
    struct Business {
        uint256 clientId;
        bool transfered;
        address to;
    }

    //untransferrable
    struct Personal {
        uint256 clientId;
    }
    
}