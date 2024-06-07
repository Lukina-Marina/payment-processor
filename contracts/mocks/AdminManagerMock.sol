// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract AdminManagerMock {
    bool isPaused;
    uint256 _serviceFee;
    address _feeReceiver;
    uint256 _extraGasAmount;

    function setIsPaused(bool newValue) external {
        isPaused = newValue;
    }

    function setServiceFee(uint256 newValue) external {
        _serviceFee = newValue;
    }

    function setFeeReceiver(address newValue) external {
        _feeReceiver = newValue;
    }

    function setExtraGasAmount(uint256 newValue) external {
        _extraGasAmount = newValue;
    }

    function paused() external view returns (bool) {
        return isPaused;
    }

    function serviceFee() external view returns(uint256) {
        return _serviceFee;
    }

    function feeReceiver() external view returns(address) {
        return _feeReceiver;
    }

    function extraGasAmount() external view returns(uint256) {
        return _extraGasAmount;
    }
}