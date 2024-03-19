// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ISubscriptionManager} from "./interfaces/ISubscriptionManager.sol";
import {IUserManager} from "./interfaces/IUserManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CheckTokenLib} from "./lib/CheckToken.sol";
import {IAdminManager} from "./interfaces/IAdminManager.sol";

contract UserManager is IUserManager {

    /* struct UserInfo {
        // поля, которые содержат информацию о пользователе
        UserSubscriptionInfop[] _activeSubscriptions;
    }
    mapping (address => UserInfo) public user; */

    mapping (address => ActiveSubscriptionInfo[]) private _activeSubscriptions;

    address public subscriptionManager;

    address public adminManager;

    constructor(address _subscriptionManager, address _adminManager) {
        subscriptionManager = _subscriptionManager;
        adminManager = _adminManager;
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

    
    function renewSubscription(address user, uint256 activeSubscriptionId) public {

        uint256 gasLeftStart = gasleft();

        require(!isActiveSubscription(user, activeSubscriptionId), "UserManager: Subscription is active");
        // _activeSubscriptions - mapping (address => ActiveSubscriptionInfo[])
        // _activeSubscriptions[user] - ActiveSubscriptionInfo[]
        // _activeSubscriptions[user][activeSubscriptionId] - ActiveSubscriptionInfo

        // чтобы вызвать контракт нужно сделать вот так
        // ISubscriptionManager(переменная, которая содержит адрес контракта).название функции(аргументы функции);

        ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[user][activeSubscriptionId];

        ISubscriptionManager.Subscription memory subscription = ISubscriptionManager(subscriptionManager).subscription(activeSubscriptionInfo.appId, activeSubscriptionInfo.subscriptionId);

        require(subscription.isPaused == false, "UserManager: Subscription is paused");

        uint256 tokenIndex = CheckTokenLib.findIndexOf(subscription.tokens, activeSubscriptionInfo.token);
        require(tokenIndex < subscription.tokens.length, "UserManager: No such token");
        
        uint256 serviceFee = IAdminManager(adminManager).serviceFee();
        address feeReceiver = IAdminManager(adminManager).feeReceiver();
        uint256 extraGasAmount = IAdminManager(adminManager).extraGasAmount();

        uint256 serviceFeeAmount = subscription.amounts[tokenIndex] * serviceFee / 10000;
        uint256 gasLeftEnd = gasleft();
        uint256 transactionFeeAmount = (gasLeftStart - gasLeftEnd + extraGasAmount) * tx.gasprice;
        
        uint256 transferAmount = subscription.amounts[tokenIndex] - serviceFeeAmount - transactionFeeAmount;

        IERC20(activeSubscriptionInfo.token).transferFrom(msg.sender, subscription.reciever, transferAmount);
        IERC20(activeSubscriptionInfo.token).transferFrom(msg.sender, feeReceiver, serviceFeeAmount + transactionFeeAmount);

        _activeSubscriptions[user][activeSubscriptionId].subscriptionEndTime = block.timestamp + subscription.subscriptionPeriod;

        emit RenewSubscription(msg.sender, activeSubscriptionId, activeSubscriptionInfo, subscription);
    }

    function isActiveSubscription(address user, uint256 activeSubscriptionId) public view returns(bool) {
        ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[user][activeSubscriptionId];

        ISubscriptionManager.Subscription memory subscription = ISubscriptionManager(subscriptionManager).subscription(activeSubscriptionInfo.appId, activeSubscriptionInfo.subscriptionId);

        if (subscription.isPaused) {
            return false;
        } else {
            return activeSubscriptionInfo.subscriptionEndTime > block.timestamp;
        }
    }

    function addSubscription(uint256 appId, uint256 subscriptionId, address token) external {

        for (uint i = 0; i < _activeSubscriptions[msg.sender].length; i++) {
            ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[msg.sender][i];
            require(activeSubscriptionInfo.appId != appId || activeSubscriptionInfo.subscriptionId != subscriptionId, "UserManager: You have already subscribed");
        }
        require(appId < ISubscriptionManager(subscriptionManager).appsLenght(), "UserManager: Wrong appId");
        require(subscriptionId < ISubscriptionManager(subscriptionManager).subscriptionLength(appId), "UserManager: Wrong subscriptionId");

        ISubscriptionManager.Subscription memory _subscription = ISubscriptionManager(subscriptionManager).subscription(appId, subscriptionId);
        
        uint256 tokenIndex = CheckTokenLib.findIndexOf(_subscription.tokens, token);

        require(tokenIndex < _subscription.tokens.length, "UserManager: No such token");

        _activeSubscriptions[msg.sender].push(
            ActiveSubscriptionInfo({
                appId: appId,
                subscriptionId: subscriptionId,
                subscriptionEndTime: 0,
                token: token
            })
        );
        renewSubscription(msg.sender, _activeSubscriptions[msg.sender].length);
    }

    function cancelSubscription(uint256 activeSubscriptionId) external {
        ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[msg.sender][activeSubscriptionId];

        _activeSubscriptions[msg.sender][activeSubscriptionId] = _activeSubscriptions[msg.sender][_activeSubscriptions[msg.sender].length-1];

        _activeSubscriptions[msg.sender].pop();
    }
}