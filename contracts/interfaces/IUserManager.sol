// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ISubscriptionManager} from "./ISubscriptionManager.sol";

interface IUserManager {

    event RenewedSubscription(address indexed user, uint256 indexed activeSubscriptionIndex, ActiveSubscriptionInfo activeSubscriptionInfo, ISubscriptionManager.Subscription subscription);
    event FeeCharged(address indexed token, uint256 serviceFeeAmount, uint256 transactionFeeAmount, uint256 transactionFeeAmountToken);
    event AddedSubscription(address indexed user, uint256 indexed appId, uint256 indexed subscriptionId, uint256 activeSubscriptionId, address token);
    event CanceledSubscription(address indexed user, uint256 activeSubscriptionId, uint256 lastElementId, ActiveSubscriptionInfo activeSubscriptionInfo);
    event PaymentTokenChanged(address indexed user, address indexed oldToken, address indexed newToken, uint256 activeSubscriptionId);

    struct ActiveSubscriptionInfo {
        uint256 appId;
        uint256 subscriptionId;
        uint256 subscriptionEndTime;
        address token;
    }
    
    // Адрес смарт-контракта subscriptionManager
    function subscriptionManager() external view returns(address);
    // Адрес смарт-контракта adminManager
    function adminManager() external view returns(address);
    // Продление подписки
    function renewSubscription(address user, uint256 activeSubscriptionId) external;
    // Активна ли подписка
    function isActiveSubscription(address user, uint256 activeSubscriptionId) external view returns(bool);
    // Добавление подписки
    function addSubscription(uint256 appId, uint256 subscriptionId, address token) external;
    // Отмена подписки
    function cancelSubscription(uint256 activeSubscriptionId) external;
    // Изменение токена оплаты
    function changePaymentToken(uint256 activeSubscriptionId, address newPaymentToken) external;
    // Смена одной подписки на другую внутри одного приложения
    function changeSubscriptionInApp(uint256 activeSubscriptionId, uint256 newSubscriptionId) external;
    // Возвращает информацию об активной подписке пользователя
    function activeSubscription(address user, uint256 index) external view returns(ActiveSubscriptionInfo memory);
    // Возвращает количество активных подписок пользователя
    function activeSubscriptionsLength(address user) external view returns(uint256);
}
