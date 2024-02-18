// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUserManager {

    struct ActiveSubscriptionInfo {
        uint256 appId;
        uint256 subscriptionId;
        //bool isActive;
        uint256 subscriptionEndTime;
    }

    function subscriptionManager() external view returns(address);
    
    function renewSubscription(address user, uint256 activeSubscriptionId) external;
}
