// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ISubscriptionManager} from "./ISubscriptionManager.sol";

interface IUserManager {

    event RenewSubscription(address indexed user, uint256 indexed activeSubscriptionIndex, ActiveSubscriptionInfo activeSubscriptionInfo, ISubscriptionManager.Subscription subscription);

    struct ActiveSubscriptionInfo {
        uint256 appId;
        uint256 subscriptionId;
        uint256 subscriptionEndTime;
    }

    function subscriptionManager() external view returns(address);
    
    function renewSubscription(address user, uint256 activeSubscriptionId) external;
}
