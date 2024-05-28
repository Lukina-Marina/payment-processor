// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract AggregatorV3Mock {
    uint256 answer;

    function setAnswer(uint256 newAnswer) external {
        answer = newAnswer;
    }

    function decimals() external view returns(uint8) {
        return 8;
    }

    function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 _answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        _answer = int256(answer);
        updatedAt = block.timestamp;
        roundId = 1;
    }
}