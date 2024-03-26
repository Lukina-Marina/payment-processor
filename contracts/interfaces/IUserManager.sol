// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ISubscriptionManager} from "./ISubscriptionManager.sol";

interface IUserManager {

    event RenewedSubscription(address indexed user, uint256 indexed activeSubscriptionIndex, ActiveSubscriptionInfo activeSubscriptionInfo, ISubscriptionManager.Subscription subscription);
    event FeeCharged(address indexed token, uint256 serviceFeeAmount, uint256 transactionFeeAmount, uint256 transactionFeeAmountToken);
    event AddedSubscription(address indexed user, uint256 indexed appId, uint256 indexed subscriptionId, address token);
    event CanceledSubscription(address indexed user, uint256 activeSubscriptionId, ActiveSubscriptionInfo activeSubscriptionInfo);
    event PaymentTokenChanged(address indexed user, address indexed oldToken, address indexed newToken, uint256 activeSubscriptionId);

    struct ActiveSubscriptionInfo {
        uint256 appId;
        uint256 subscriptionId;
        uint256 subscriptionEndTime;
        address token;
    }

    function subscriptionManager() external view returns(address);
    
    function adminManager() external view returns(address);
    
    function renewSubscription(address user, uint256 activeSubscriptionId) external;

    function isActiveSubscription(address user, uint256 activeSubscriptionId) external view returns(bool);

    function addSubscription(uint256 appId, uint256 subscriptionId, address token) external;

    function cancelSubscription(uint256 activeSubscriptionId) external;

    function changePaymentToken(uint256 activeSubscriptionId, address newPaymentToken) external;

    function changeSubscriptionInApp(uint256 activeSubscriptionId, uint256 newSubscriptionId) external;
}
