// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAdminManager {
    event ServiceFeeChanged(uint256 oldValue, uint256 newValue);
    event FeeReceiverChanged(address oldValue, address newValue);
    event ExtraGasAmountChanged(uint256 oldValue, uint256 newValue);

    function serviceFee() external view returns(uint256);
    function feeReceiver() external view returns(address);
    function extraGasAmount() external view returns(uint256);
    function setServiceFee(uint256 newServiceFee) external;
    function setFeeReceiver(address newFeeReceiver) external;
    function setExtraGasAmount(uint256 newExtraGasAmount) external;
}