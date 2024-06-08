// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ISubscriptionManager} from "./interfaces/ISubscriptionManager.sol";
import {IUserManager} from "./interfaces/IUserManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CheckTokenLib} from "./lib/CheckToken.sol";
import {IAdminManager} from "./interfaces/IAdminManager.sol";
import {IPriceCalculator} from "./interfaces/IPriceCalculator.sol";

contract UserManager is IUserManager {
    mapping (address => ActiveSubscriptionInfo[]) private _activeSubscriptions;

    address public subscriptionManager;

    address public adminManager;

    address public priceCalculator;

    constructor(address _subscriptionManager, address _adminManager, address _priceCalculator) {
        subscriptionManager = _subscriptionManager;
        adminManager = _adminManager;
        priceCalculator = _priceCalculator;
    }
    
    function renewSubscription(address user, uint256 activeSubscriptionId) public {

        uint256 gasLeftStart = gasleft();

        require(!IAdminManager(adminManager).paused(), "UserManager: Paused");

        require(!isActiveSubscription(user, activeSubscriptionId), "UserManager: Subscription is active");
        // _activeSubscriptions - mapping (address => ActiveSubscriptionInfo[])
        // _activeSubscriptions[user] - ActiveSubscriptionInfo[]
        // _activeSubscriptions[user][activeSubscriptionId] - ActiveSubscriptionInfo

        // чтобы вызвать контракт нужно
        // ISubscriptionManager(переменная, которая содержит адрес контракта).название функции(аргументы функции);

        ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[user][activeSubscriptionId];

        ISubscriptionManager.Subscription memory subscription = ISubscriptionManager(subscriptionManager).subscription(activeSubscriptionInfo.appId, activeSubscriptionInfo.subscriptionId);

        require(subscription.isPaused == false, "UserManager: Subscription is paused");

        uint256 tokenIndex = _checkToken(subscription.tokens, activeSubscriptionInfo.token);
        
        uint256 serviceFeeAmount;
        {
            uint256 serviceFee = IAdminManager(adminManager).serviceFee();
            serviceFeeAmount = subscription.amounts[tokenIndex] * serviceFee / 10000;
        }
        
        address feeReceiver = IAdminManager(adminManager).feeReceiver();
        uint256 extraGasAmount = IAdminManager(adminManager).extraGasAmount();

        uint256 transactionFeeAmountToken;
        {
            uint256 gasLeftEnd = gasleft();
            uint256 transactionFeeAmount = (gasLeftStart - gasLeftEnd + extraGasAmount) * tx.gasprice;
            transactionFeeAmountToken = IPriceCalculator(priceCalculator).getTokenFromETH(activeSubscriptionInfo.token, transactionFeeAmount);

            emit FeeCharged(activeSubscriptionInfo.token, serviceFeeAmount, transactionFeeAmount, transactionFeeAmountToken);
        }
        
        uint256 totalFee = serviceFeeAmount + transactionFeeAmountToken;

        require(subscription.amounts[tokenIndex] > totalFee, "UserManager: Too big fee");
        uint256 transferAmount = subscription.amounts[tokenIndex] - totalFee;

        IERC20(activeSubscriptionInfo.token).transferFrom(user, subscription.reciever, transferAmount);
        IERC20(activeSubscriptionInfo.token).transferFrom(user, feeReceiver, totalFee);

        uint256 newSubscriptionEndTime = block.timestamp + subscription.subscriptionPeriod;
        _activeSubscriptions[user][activeSubscriptionId].subscriptionEndTime = newSubscriptionEndTime;
        activeSubscriptionInfo.subscriptionEndTime = newSubscriptionEndTime;

        emit RenewedSubscription(msg.sender, activeSubscriptionId, activeSubscriptionInfo, subscription);
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

    function addSubscription(uint256 appId, uint256 subscriptionId, address token) public {

        for (uint i = 0; i < _activeSubscriptions[msg.sender].length; i++) {
            ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[msg.sender][i];
            require(activeSubscriptionInfo.appId != appId || activeSubscriptionInfo.subscriptionId != subscriptionId, "UserManager: You have already subscribed");
        }
        require(appId < ISubscriptionManager(subscriptionManager).appsLenght(), "UserManager: Wrong appId");
        require(subscriptionId < ISubscriptionManager(subscriptionManager).subscriptionLength(appId), "UserManager: Wrong subscriptionId");

        ISubscriptionManager.Subscription memory _subscription = ISubscriptionManager(subscriptionManager).subscription(appId, subscriptionId);
        
        _checkToken(_subscription.tokens, token);

        _activeSubscriptions[msg.sender].push(
            ActiveSubscriptionInfo({
                appId: appId,
                subscriptionId: subscriptionId,
                subscriptionEndTime: 0,
                token: token
            })
        );
        uint256 activeSubscriptionId = _activeSubscriptions[msg.sender].length - 1;

        emit AddedSubscription(msg.sender, appId, subscriptionId, activeSubscriptionId, token);

        renewSubscription(msg.sender, activeSubscriptionId);
    }

    function cancelSubscription(uint256 activeSubscriptionId) public {
        ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[msg.sender][activeSubscriptionId];

        uint256 lastElementId = _activeSubscriptions[msg.sender].length-1;
        _activeSubscriptions[msg.sender][activeSubscriptionId] = _activeSubscriptions[msg.sender][lastElementId];

        _activeSubscriptions[msg.sender].pop();

        emit CanceledSubscription(msg.sender, activeSubscriptionId, lastElementId, activeSubscriptionInfo);
    }

    function changePaymentToken(uint256 activeSubscriptionId, address newPaymentToken) external {

        uint256 appId = _activeSubscriptions[msg.sender][activeSubscriptionId].appId;
        uint256 subscriptionId = _activeSubscriptions[msg.sender][activeSubscriptionId].subscriptionId;

        ISubscriptionManager.Subscription memory subscription = ISubscriptionManager(subscriptionManager).subscription(appId, subscriptionId);

        _checkToken(subscription.tokens, newPaymentToken);

        address oldToken = _activeSubscriptions[msg.sender][activeSubscriptionId].token;

        _activeSubscriptions[msg.sender][activeSubscriptionId].token = newPaymentToken;

        emit PaymentTokenChanged(msg.sender, oldToken, newPaymentToken, activeSubscriptionId);
    }

    function changeSubscriptionInApp(uint256 activeSubscriptionId, uint256 newSubscriptionId) external {
        ActiveSubscriptionInfo memory activeSubscriptionInfo = _activeSubscriptions[msg.sender][activeSubscriptionId];

        cancelSubscription(activeSubscriptionId);

        addSubscription(activeSubscriptionInfo.appId, newSubscriptionId, activeSubscriptionInfo.token);
    }

    function activeSubscription(address user, uint256 index) external view returns(ActiveSubscriptionInfo memory) {
        return _activeSubscriptions[user][index];
    }

    function activeSubscriptionsLength(address user) external view returns(uint256) {
        return _activeSubscriptions[user].length;
    }

    function _checkToken(address[] memory tokens, address token) private pure returns(uint256) {
        uint256 tokenIndex = CheckTokenLib.findIndexOf(tokens, token);

        require(tokenIndex < tokens.length, "UserManager: No such token");

        return tokenIndex;
    }
}