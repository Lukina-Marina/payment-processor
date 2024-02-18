// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ISubscriptionManager} from "./interfaces/ISubscriptionManager.sol";
import {IUserManager} from "./interfaces/IUserManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UserManager is IUserManager {

    /* struct UserInfo {
        // поля, которые содержат информацию о пользователе
        UserSubscriptionInfop[] _activeSubscriptions;
    }
    mapping (address => UserInfo) public user; */

    mapping (address => ActiveSubscriptionInfo[]) private _activeSubscriptions;

    address public subscriptionManager;

    constructor(address _subscriptionManager) {
        subscriptionManager = _subscriptionManager;
    }

    // перменная типа struct ActiveSubscriptionInfo:
    // ActiveSubscriptionInfo memory activeSubscriptionInfo;
    // activeSubscriptionInfo.element

    // перменная типа массив структур struct ActiveSubscriptionInfo:
    // ActiveSubscriptionInfo[] memory activeSubscriptionInfo;
    // activeSubscriptionInfo[0].element



    // _activeSubscriptions - маппинг
    // маппинг это такая структура, которую можно представить таким образом:

    // ----------+-----------+
    // столбец 1 | столбец 2 |
    // ----------+-----------+
    //    key1   |   value1  |
    // ----------+-----------+
    //    key2   |   value2  |
    // ----------+-----------+
    
    // в нашем случае это
    // адрес пользователя 1 - [активная подписка 0 пользователя 0, активная подписка 1 пользователя 0]
    // адрес пользователя 2 - [активная подписка 0 пользователя 1, активная подписка 1 пользователя 1]

    
    function renewSubscription(address user, uint256 activeSubscriptionId) external {
        // _activeSubscriptions - mapping (address => ActiveSubscriptionInfo[])
        // _activeSubscriptions[user] - ActiveSubscriptionInfo[]
        // _activeSubscriptions[user][activeSubscriptionId] - ActiveSubscriptionInfo

        // чтобы вызвать контракт нужно сделать вот так
        // ISubscriptionManager(переменная, которая содержит адрес контракта).название функции(аргументы функции);


        // 4. Нужно придумать какие проверки добавить, чтобы не снимать деньги с пользователя, до того как закончится подписка:
        //require(IUserManager.ActiveSubscriptionInfo.isActive = false, "Subscription is active");

        ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[user][activeSubscriptionId];

        ISubscriptionManager.Subscription memory subscription = ISubscriptionManager(subscriptionManager).subscription(activeSubscriptionInfo.appId, activeSubscriptionInfo.subscriptionId);

        IERC20(subscription.token).transferFrom(msg.sender, subscription.reciever, subscription.amount);

        _activeSubscriptions[user][activeSubscriptionId].subscriptionEndTime = block.timestamp;
    }
}