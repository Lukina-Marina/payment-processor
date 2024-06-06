// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract AggregatorV3Mock {
    uint256 answer;
    uint80 roundId = 1;
    bool useTimestamp = true;
    uint256 updatedAt;
    uint8 _decimals = 12;

    function setAnswer(uint256 newAnswer) external {
        answer = newAnswer;
    }

    function setRoundId(uint80 newAnswer) external {
        roundId = newAnswer;
    }

    function setUseTimestamp(bool newAnswer) external {
        useTimestamp = newAnswer;
    }

    function setUpdatedAt(uint256 newAnswer) external {
        updatedAt = newAnswer;
    }

    function setDecimals(uint8 newDecimals) external {
        _decimals = newDecimals;
    }

    function decimals() external view returns(uint8) {
        return _decimals;
    }

    function latestRoundData()
    external
    view
    returns (uint80 _roundId, int256 _answer, uint256 /* startedAt */, uint256 _updatedAt, uint80 /* answeredInRound */) {
        _answer = int256(answer);
        if (useTimestamp) {
            _updatedAt = block.timestamp;
        } else {
            _updatedAt = updatedAt;
        }
        _roundId = roundId;
    }
}