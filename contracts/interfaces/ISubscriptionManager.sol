// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISubscriptionManager {
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

    function addApp(string memory name, string memory description) external;

    function addSubscription(uint256 appId, Subscription memory subscription) external;

    function changeSubscription(uint256 appId, uint256 subscriptionId, Subscription memory newSubscription) external;

    function pauseSubscription(uint256 appId, uint256 subscriptionId) external;

    function unpauseSubscription(uint256 appId, uint256 subscriptionId) external;

    function appsLenght() external view returns(uint256);

    function apps(uint256 appId) external view returns(App memory);

    function subscriptionLength(uint256 appId) external view returns(uint256);

    function subscription(uint256 appId, uint256 subscriptionId) external view returns(Subscription memory);
}