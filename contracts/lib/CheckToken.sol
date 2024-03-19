// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ISubscriptionManager} from "../interfaces/ISubscriptionManager.sol";
import {IUserManager} from "../interfaces/IUserManager.sol";


library CheckTokenLib {
    function findIndexOf(address[] memory array, address element) internal pure returns(uint256) {

        for (uint i = 0; i < array.length; i++) {
            if (element == array[i]) {
                return i;
            }
        }
        return array.length;
    }
}