// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract PriceCalculatorMock {
    uint256 price;

    function setPrice(uint256 newValue) external {
        price = newValue;
    }

    function getTokenFromETH(address, uint256) external view returns (uint256) {
        return price;
    }
}