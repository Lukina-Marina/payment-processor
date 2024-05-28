// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {IAdminManager} from "./interfaces/IAdminManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract AdminManager is IAdminManager, Ownable, Pausable {
    //percentDenominator = 100_00 = 100%
    //amount * 1_00 / percentDenominator = 1% от amount
    //amount * 15_20 / percentDenominator = 15.2% от amount
    uint256 public serviceFee;
    address public feeReceiver;
    uint256 public extraGasAmount;
    uint256 private constant PERCENT_DENOMINATOR = 10000;

    constructor(uint256 _serviceFee, address _feeReceiver, uint256 _extraGasAmount) {
        require(_serviceFee < PERCENT_DENOMINATOR, "AdminManager: Too big service fee");
        require(_feeReceiver != address(0), "AdminManager: Zero fee receiver");
        require(_extraGasAmount > 0, "AdminManager: Zero extra gas amount");

        serviceFee = _serviceFee;
        feeReceiver = _feeReceiver;
        extraGasAmount = _extraGasAmount;

        emit ServiceFeeChanged(0, _serviceFee);
        emit FeeReceiverChanged(address(0), _feeReceiver);
        emit ExtraGasAmountChanged(0, _extraGasAmount);
    }

    function setServiceFee(uint256 newServiceFee) external onlyOwner {
        require(newServiceFee < PERCENT_DENOMINATOR, "AdminManager: Too big service fee");

        uint256 oldValue = serviceFee;
        serviceFee = newServiceFee;

        emit ServiceFeeChanged(oldValue, newServiceFee);
    }

    function setFeeReceiver(address newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), "AdminManager: Zero fee receiver");

        address oldValue = feeReceiver;
        feeReceiver = newFeeReceiver;

        emit FeeReceiverChanged(oldValue, newFeeReceiver);
    }

    function setExtraGasAmount(uint256 newExtraGasAmount) external onlyOwner {
        require(newExtraGasAmount > 0, "AdminManager: Zero extra gas amount");

        uint256 oldValue = extraGasAmount;
        extraGasAmount = newExtraGasAmount;

        emit ExtraGasAmountChanged(oldValue, newExtraGasAmount);
    }

    function paused() public view virtual override(IAdminManager, Pausable) returns (bool) {
        return super.paused();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}