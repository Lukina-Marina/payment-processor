// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IPriceCalculator} from "./interfaces/IPriceCalculator.sol";

contract PriceCalculator is IPriceCalculator {
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => TokenConfig) private _tokenConfig;

    uint256 private constant USD_DECIMALS = 18;

    function setTokenConfig(address token, address oracle, uint32 oracleHeartbeat) external override {
        if (oracle == address(0)) {
            require(oracleHeartbeat == 0, "PriceCalculator: Bad Oracle Heartbeat");

            delete _tokenConfig[token];

            emit TokenConfigDeleted(token);

            return;
        }

        require(oracleHeartbeat != 0, "PriceCalculator: Bad Oracle Heartbeat");

        TokenConfig memory tokenConfigToSet;
        tokenConfigToSet.oracleAddress = oracle;
        tokenConfigToSet.oracleDecimals = AggregatorV3Interface(oracle).decimals();
        tokenConfigToSet.oracleHeartbeat = oracleHeartbeat;

        if (token == NATIVE_TOKEN_ADDRESS) {
            tokenConfigToSet.tokenDecimals = 18;
        } else {
            tokenConfigToSet.tokenDecimals = IERC20Metadata(token).decimals();
        }

        // to check that oracle answer is good
        _getOracleAnswer(tokenConfigToSet);

        _tokenConfig[token] = tokenConfigToSet;

        emit TokenConfigSet(token, tokenConfigToSet);
    }

    function tokenConfig(address token) external view override returns (TokenConfig memory) {
        return _tokenConfig[token];
    }

    function getTokenFromETH(address token, uint256 ethAmount) external view returns (uint256) {
        uint256 usdAmount = _getUsdPriceFromToken(NATIVE_TOKEN_ADDRESS, ethAmount);
        return _getTokenPriceFromUsd(token, usdAmount);
    }

    function _getUsdPriceFromToken(address token, uint256 tokenAmount) private view returns (uint256) {
        TokenConfig memory tokenConfigMem = _tokenConfig[token];

        require(tokenConfigMem.oracleAddress != address(0), "PriceCalculator: Not Supported Token");

        uint256 oracleAnswer = _getOracleAnswer(tokenConfigMem);

        if (USD_DECIMALS < tokenConfigMem.tokenDecimals + tokenConfigMem.oracleDecimals) {
            return (tokenAmount * oracleAnswer) / 10 ** (tokenConfigMem.tokenDecimals + tokenConfigMem.oracleDecimals - USD_DECIMALS);
        } else {
            return (tokenAmount * oracleAnswer) * 10 ** (USD_DECIMALS - tokenConfigMem.tokenDecimals - tokenConfigMem.oracleDecimals);
        }
    }

    function _getTokenPriceFromUsd(address token, uint256 usdAmount) private view returns (uint256) {
        TokenConfig memory tokenConfigMem = _tokenConfig[token];

        require(tokenConfigMem.oracleAddress != address(0), "PriceCalculator: Not Supported Token");

        uint256 oracleAnswer = _getOracleAnswer(tokenConfigMem);

        if (USD_DECIMALS > tokenConfigMem.tokenDecimals + tokenConfigMem.oracleDecimals) {
            return usdAmount * 10 ** (USD_DECIMALS - tokenConfigMem.oracleDecimals - tokenConfigMem.tokenDecimals) / oracleAnswer;
        } else {
            return usdAmount * 10 ** (tokenConfigMem.oracleDecimals + tokenConfigMem.tokenDecimals - USD_DECIMALS) / oracleAnswer;
        }
    }

    function _getOracleAnswer(TokenConfig memory tokenConfigMem) private view returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,

        ) = AggregatorV3Interface(tokenConfigMem.oracleAddress).latestRoundData();

        require(answer > 0, "PriceCalculator: Bad Oracle Answer");

        require(roundId != 0, "PriceCalculator: Oracle RoundId Is Zero");

        require(updatedAt <= block.timestamp && block.timestamp - updatedAt <= tokenConfigMem.oracleHeartbeat, "PriceCalculator: Oracle UpdatedAt Is Bad");

        return uint256(answer);
    }
}
