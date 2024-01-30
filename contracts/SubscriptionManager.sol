// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SubscriptionManager {
    event AppAdded(address indexed owner, uint256 indexed appIndex, string name, string description);
    event SubscriptionAdded(address indexed owner, uint256 indexed appIndex, uint256 indexed subscriptionIndex, Subscription subscription);
    event SubscriptionChanging(address indexed owner, uint256 indexed appIndex, uint256 indexed subscriptionIndex, Subscription newSubscription);
    event SubscriptionPaused(address indexed owner, uint256 indexed appIndex, uint256 indexed subscriptionIndex);
    event SubscriptionUnpaused(address indexed owner, uint256 indexed appIndex, uint256 indexed subscriptionIndex);

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

        emit AppAdded(msg.sender, apps.length - 1, name, description);
    }

    function addSubscription(uint256 appId, Subscription memory subscription) external {
        require(apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        apps[appId].subscriptions.push(subscription);

        emit SubscriptionAdded(msg.sender, appId, apps[appId].subscriptions.length - 1, subscription);
    }

    function changeSubscription(uint256 appId, uint256 subscriptionId, Subscription memory newSubscription) external {
        require(apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        apps[appId].subscriptions[subscriptionId] = newSubscription;

        emit SubscriptionChanging(msg.sender, appId, subscriptionId, newSubscription);
    }

    function pauseSubscription(uint256 appId, uint256 subscriptionId) external {
        require(apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        apps[appId].subscriptions[subscriptionId].isPaused = true;

        emit SubscriptionPaused(msg.sender, appId, subscriptionId);
    }

    function unpauseSubscription(uint256 appId, uint256 subscriptionId) external {
        require(apps[appId].owner == msg.sender, "SubscriptionManager: caller is not the owner");

        apps[appId].subscriptions[subscriptionId].isPaused = false;

        emit SubscriptionUnpaused(msg.sender, appId, subscriptionId);
    }
}