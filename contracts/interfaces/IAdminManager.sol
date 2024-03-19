// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAdminManager {
    function serviceFee() external view returns(uint256);
    function feeReceiver() external view returns(address);
    function extraGasAmount() external view returns(uint256);
}