// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAdminManager {
    event ServiceFeeChanged(uint256 oldValue, uint256 newValue);
    event FeeReceiverChanged(address oldValue, address newValue);
    event ExtraGasAmountChanged(uint256 oldValue, uint256 newValue);

    // Возвращает процент комиссии протокола
    function serviceFee() external view returns(uint256);
    // Возвращает адрес, на который приходят комиссии
    function feeReceiver() external view returns(address);
    // Возвращает количество дополнительного газа, который
    // потратится при продлении подписки
    function extraGasAmount() external view returns(uint256);
    // Устанавливает переменную serviceFee
    function setServiceFee(uint256 newServiceFee) external;
    // Устанавливает переменную feeReceiver
    function setFeeReceiver(address newFeeReceiver) external;
    // Устанавливает переменную extraGasAmount
    function setExtraGasAmount(uint256 newExtraGasAmount) external;
    // Узнает, остановлен ли контракт или нет
    function paused() external view returns (bool);
    // Ставит на паузу контракт
    function pause() external;
    // Снимает с паузы контракт
    function unpause() external;
}