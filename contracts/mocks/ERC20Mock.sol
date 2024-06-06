// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20("Test token", "TEST") {
    uint8 _decimals = 12;

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function setDecimals(uint8 newDecimals) external {
        _decimals = newDecimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}