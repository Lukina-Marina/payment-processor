pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReceiveToken {
    struct Subscription {
        uint256 amount;
        uint256 subscriptionPeriod;
        address reciever;
        address token;
    }
    
    Subscription[] public subscriptions;

    function addSubscription(Subscription memory subscription) external {
        subscriptions.push(subscription);
    }

    function receiveTokens(address token, uint256 amount) external {
        address from = msg.sender;
        address to = address(this);
        IERC20(token).transferFrom(from, to, amount);
    }
}