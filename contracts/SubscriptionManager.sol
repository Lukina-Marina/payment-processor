// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SubscriptionManager {
    struct App {
        address owner;
        Subscription[] subscriptions;
        string name;
        string description;
    }

    struct Subscription {
        string name;
        uint256 amount;
        uint256 subscriptionPeriod;
        address reciever;
        address token;
        bool isPaused;
    }
    
    App[] public apps;

    function addApp(string memory name, string memory description) external {
        apps.push(
            App({
                owner: msg.sender,
                subscriptions: new Subscription[](0),
                name: name,
                description: description
            })
        );
    }

    function addSubscription(uint256 appId, Subscription memory subscription) external {
        require(apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        apps[appId].subscriptions.push(subscription);
    }

    function changeSubscription(uint256 appId, uint256 subscriptionId, Subscription memory newSubscription) external {
        require(apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        apps[appId].subscriptions[subscriptionId] = newSubscription;
    }

    function pauseSubscription(uint256 appId, uint256 subscriptionId) external {
        require(apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        apps[appId].subscriptions[subscriptionId].isPaused = true;
    }

    function unpauseSubscription(uint256 appId, uint256 subscriptionId) external {
        require(apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        apps[appId].subscriptions[subscriptionId].isPaused = false;
    }
}