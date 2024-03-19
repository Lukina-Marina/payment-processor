// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IAdminManager} from "./interfaces/IAdminManager.sol";

contract AdminManager is IAdminManager {
    //percentDenominator = 100_00 = 100%
    //amount * 1_00 / percentDenominator = 1% от amount
    //amount * 15_20 / percentDenominator = 15.2% от amount
    uint256 public serviceFee = 200;
    address public feeReceiver;
    uint256 public extraGasAmount;
}