// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IPriceCalculator {

    struct TokenConfig {
        uint8 tokenDecimals;
        uint8 oracleDecimals;
        uint32 oracleHeartbeat;
        address oracleAddress;
    }

    event TokenConfigSet(address indexed token, TokenConfig tokenConfig);
    event TokenConfigDeleted(address indexed token);

    function tokenConfig(
        address token
    ) external view returns (TokenConfig memory);

    function setTokenConfig(
        address token,
        address oracle,
        uint32 oracleHeartbeat
    ) external;
}
