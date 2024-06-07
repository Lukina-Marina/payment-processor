// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ISubscriptionManager} from "../interfaces/ISubscriptionManager.sol";

contract SubscriptionManagerMock {
    ISubscriptionManager.Subscription _subscription;
    uint256 _appsLenght;
    uint256 _subscriptionLength;

    function setSubscription(ISubscriptionManager.Subscription memory newValue) external {
        _subscription = newValue;
    }

    function setAppsLenght(uint256 newValue) external {
        _appsLenght = newValue;
    }

    function setSubscriptionLength(uint256 newValue) external {
        _subscriptionLength = newValue;
    }

    function subscription(uint256, uint256) external view returns(ISubscriptionManager.Subscription memory) {
        return _subscription;
    }

    function appsLenght() external view returns(uint256) {
        return _appsLenght;
    }

    function subscriptionLength(uint256) external view returns(uint256) {
        return _subscriptionLength;
    }
}