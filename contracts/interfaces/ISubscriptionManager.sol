// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface ISubscriptionManager {
    event AppAdded(address indexed owner, uint256 indexed appIndex, string name, string description);
    event SubscriptionAdded(address indexed owner, uint256 indexed appIndex, uint256 indexed subscriptionIndex, Subscription subscription);
    event SubscriptionChanged(address indexed owner, uint256 indexed appIndex, uint256 indexed subscriptionIndex, Subscription newSubscription);
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
        uint256[] amounts;
        uint256 subscriptionPeriod;
        address reciever;
        address[] tokens;
        bool isPaused;
    }

    // Создание приложения
    function addApp(string memory name, string memory description) external;
    // Добавление подписки
    function addSubscription(uint256 appId, Subscription memory subscription) external;
    // Изменение подписки
    function changeSubscription(uint256 appId, uint256 subscriptionId, Subscription memory newSubscription) external;
    // Остановка подписки на паузу
    function pauseSubscription(uint256 appId, uint256 subscriptionId) external;
    // Снатия подписки с паузы
    function unpauseSubscription(uint256 appId, uint256 subscriptionId) external;
    // Количество добавленных приложений в протоколе
    function appsLenght() external view returns(uint256);
    // Информация о приложении
    function apps(uint256 appId) external view returns(App memory);
    // Количество подписок в приложении
    function subscriptionLength(uint256 appId) external view returns(uint256);
    // Информация о подписке
    function subscription(uint256 appId, uint256 subscriptionId) external view returns(Subscription memory);
}