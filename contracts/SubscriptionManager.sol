// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SubscriptionManager {
    struct Subscription {
        uint256 amount;
        uint256 subscriptionPeriod;
        address reciever;
        address token;
        bool isPaused;
    }
    
    Subscription[] public subscriptions;

    function addSubscription(Subscription memory subscription) external {
        subscriptions.push(subscription);
    }

    function changeSubscription(uint256 subscriptionId, Subscription memory newSubscription) external {
        subscriptions[subscriptionId] = newSubscription;
    }

    function pauseSubscription(uint256 subscriptionId) external {
        subscriptions[subscriptionId].isPaused = true;
    }

    function unpauseSubscription(uint256 subscriptionId) external {
        subscriptions[subscriptionId].isPaused = false;
    }

    function receiveTokens(address token, uint256 amount) external {
        address from = msg.sender;
        address to = address(this);
        IERC20(token).transferFrom(from, to, amount);
    }
}