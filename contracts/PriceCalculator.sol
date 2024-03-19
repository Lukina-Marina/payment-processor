// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IPriceCalculator} from "./interfaces/IPriceCalculator.sol";

contract PriceCalculator is IPriceCalculator {
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => TokenConfig) private _tokenConfig;

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

    function _getTokenPriceFromUSDPrice(uint256 usdPrice, address token) private view returns (uint256) {
        TokenConfig memory tokenConfigMem = _tokenConfig[token];

        require(tokenConfigMem.oracleAddress != address(0), "PriceCalculator: Not Supported Token");

        uint256 oracleAnswer = _getOracleAnswer(tokenConfigMem);

        return
            (usdPrice *
                10 **
                    (tokenConfigMem.tokenDecimals +
                        tokenConfigMem.oracleDecimals)) /
            (oracleAnswer * _USD_DENOMINATOR);
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
