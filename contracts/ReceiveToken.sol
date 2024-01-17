pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReceiveToken {
    function receiveTokens(address token, uint256 amount) external {
        address from = msg.sender;
        address to = address(this);
        IERC20(token).transferFrom(from, to, amount);
    }
}