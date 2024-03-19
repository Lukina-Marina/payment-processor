// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISubscriptionManager} from "./interfaces/ISubscriptionManager.sol";

contract SubscriptionManager is ISubscriptionManager {
    App[] private _apps;

    function addApp(string memory name, string memory description) external {
        uint256 appIndex = _apps.length;
        _apps.push();

        _apps[appIndex].owner = msg.sender;
        _apps[appIndex].name = name;
        _apps[appIndex].description = description;

        emit AppAdded(msg.sender, appIndex, name, description);
    }

    function addSubscription(uint256 appId, Subscription memory newSubscription) external {
        require(_apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        _checkSubscription(newSubscription);

        _apps[appId].subscriptions.push(newSubscription);

        emit SubscriptionAdded(msg.sender, appId, _apps[appId].subscriptions.length - 1, newSubscription);
    }

    function changeSubscription(uint256 appId, uint256 subscriptionId, Subscription memory newSubscription) external {
        require(_apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        _checkSubscription(newSubscription);

        _apps[appId].subscriptions[subscriptionId] = newSubscription;

        emit SubscriptionChanging(msg.sender, appId, subscriptionId, newSubscription);
    }

    function pauseSubscription(uint256 appId, uint256 subscriptionId) external {
        require(_apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        _apps[appId].subscriptions[subscriptionId].isPaused = true;

        emit SubscriptionPaused(msg.sender, appId, subscriptionId);
    }

    function unpauseSubscription(uint256 appId, uint256 subscriptionId) external {
        require(_apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        _apps[appId].subscriptions[subscriptionId].isPaused = false;

        emit SubscriptionUnpaused(msg.sender, appId, subscriptionId);
    }

    function appsLenght() external view returns(uint256) {
        return _apps.length;
    }

    function apps(uint256 appId) external view returns(App memory) {
        return _apps[appId];
    }

    function subscriptionLength(uint256 appId) external view returns(uint256) {
        return _apps[appId].subscriptions.length;
    }

    function subscription(uint256 appId, uint256 subscriptionId) external view returns(Subscription memory) {
        return _apps[appId].subscriptions[subscriptionId];
    }

    function _checkSubscription(Subscription memory _subscription) private pure {
        require(_subscription.amounts.length == _subscription.tokens.length, "SubscriptionManager: different length");
        require(_subscription.reciever != address(0), "SubscriptionManager: reciever is zero");
        require(_subscription.subscriptionPeriod != 0, "SubscriptionManager: subscriptionPeriod is zero");

        for (uint i = 0; i < _subscription.tokens.length; i++) {
            require(_subscription.tokens[i] != address(0), "SubscriptionManager: token is zero");
            require(_subscription.amounts[i] != 0, "SubscriptionManager: amount is zero");

            for (uint j = i+1; j < _subscription.tokens.length; j++) {
                require(_subscription.tokens[j] != _subscription.tokens[i], "SubscriptionManager: equil tokens");
            }
        }
    }
}