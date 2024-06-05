import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

import { expect } from "chai";

describe("Unit tests for the PriceCalculator contract", () => {
    it("Deployment tests", async () => {
        const env = await loadFixture(prepareEnv);
    });

    describe("setTokenConfig function", () => {
        it("Delete tokenConfig", async () => {
            const env = await loadFixture(prepareEnv);

            const oracleHeartbeat = 86400;
            await env.priceCalculatorContract.setTokenConfig(env.NATIVE_TOKEN_ADDRESS, env.aggregatorV3MockContract, oracleHeartbeat);

            await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.NATIVE_TOKEN_ADDRESS, ethers.ZeroAddress, 0)).emit(
                env.priceCalculatorContract, "TokenConfigDeleted"
            ).withArgs(env.NATIVE_TOKEN_ADDRESS);

            const tokenConfig = await env.priceCalculatorContract.tokenConfig(env.NATIVE_TOKEN_ADDRESS);
            expect(tokenConfig.tokenDecimals).equals(0);
            expect(tokenConfig.oracleDecimals).equals(0);
            expect(tokenConfig.oracleHeartbeat).equals(0);
            expect(tokenConfig.oracleAddress).equals(ethers.ZeroAddress);
        });

        it("Set token config for native token", async () => {
            const env = await loadFixture(prepareEnv);

            const oracleHeartbeat = 86400;
            await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.NATIVE_TOKEN_ADDRESS, env.aggregatorV3MockContract, oracleHeartbeat)).emit(
                env.priceCalculatorContract, "TokenConfigSet"
            );

            const tokenConfig = await env.priceCalculatorContract.tokenConfig(env.NATIVE_TOKEN_ADDRESS);
            expect(tokenConfig.tokenDecimals).equals(18);
            expect(tokenConfig.oracleDecimals).equals(await env.aggregatorV3MockContract.decimals());
            expect(tokenConfig.oracleHeartbeat).equals(oracleHeartbeat);
            expect(tokenConfig.oracleAddress).equals(env.aggregatorV3MockContract);
        });

        it("Set token config for ERC20 token", async () => {
            const env = await loadFixture(prepareEnv);

            const oracleHeartbeat = 86400;

            await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.erc20MockContract, env.aggregatorV3MockContract, oracleHeartbeat)).emit(
                env.priceCalculatorContract, "TokenConfigSet"
            );

            const tokenConfig = await env.priceCalculatorContract.tokenConfig(env.erc20MockContract);
            expect(tokenConfig.tokenDecimals).equals(await env.erc20MockContract.decimals());
            expect(tokenConfig.oracleDecimals).equals(await env.aggregatorV3MockContract.decimals());
            expect(tokenConfig.oracleHeartbeat).equals(oracleHeartbeat);
            expect(tokenConfig.oracleAddress).equals(env.aggregatorV3MockContract);
        });

        describe("Reverts", () => {
            it("Bad Oracle Heartbeat when deleting token config", async () => {
                const env = await loadFixture(prepareEnv);

                await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.NATIVE_TOKEN_ADDRESS, ethers.ZeroAddress, 1)).revertedWith("PriceCalculator: Bad Oracle Heartbeat");
            })

            it("Bad Oracle Heartbeat when setting token config for native token", async () => {
                const env = await loadFixture(prepareEnv);

                await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.NATIVE_TOKEN_ADDRESS, env.aggregatorV3MockContract, 0)).revertedWith("PriceCalculator: Bad Oracle Heartbeat");
            })

            it("Bad Oracle Answer", async () => {
                const env = await loadFixture(prepareEnv);

                await env.aggregatorV3MockContract.setAnswer(0);
                await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.NATIVE_TOKEN_ADDRESS, env.aggregatorV3MockContract, 1)).revertedWith("PriceCalculator: Bad Oracle Answer");
            })

            it("Oracle RoundId Is Zero", async () => {
                const env = await loadFixture(prepareEnv);

                await env.aggregatorV3MockContract.setRoundId(0);
                await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.NATIVE_TOKEN_ADDRESS, env.aggregatorV3MockContract, 1)).revertedWith("PriceCalculator: Oracle RoundId Is Zero");
            })

            it("Oracle UpdatedAt Is Bad (in future)", async () => {
                const env = await loadFixture(prepareEnv);

                const latestBlock = await ethers.provider.getBlock("latest");
                const latestBlockTimestamp = latestBlock!.timestamp;

                const txTimestamp = latestBlockTimestamp + 1000;

                await env.aggregatorV3MockContract.setUseTimestamp(false);
                await env.aggregatorV3MockContract.setUpdatedAt(txTimestamp + 1);

                await time.setNextBlockTimestamp(txTimestamp);

                await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.NATIVE_TOKEN_ADDRESS, env.aggregatorV3MockContract, 1)).revertedWith("PriceCalculator: Oracle UpdatedAt Is Bad");
            })

            it("Oracle UpdatedAt Is Bad (old updatedAt)", async () => {
                const env = await loadFixture(prepareEnv);

                const oracleHeartbeat = 2;

                const latestBlock = await ethers.provider.getBlock("latest");
                const latestBlockTimestamp = latestBlock!.timestamp;

                const txTimestamp = latestBlockTimestamp + 1000;

                await env.aggregatorV3MockContract.setUseTimestamp(false);
                await env.aggregatorV3MockContract.setUpdatedAt(txTimestamp - oracleHeartbeat - 1);

                await time.setNextBlockTimestamp(txTimestamp);

                await expect(env.priceCalculatorContract.connect(env.alice).setTokenConfig(env.NATIVE_TOKEN_ADDRESS, env.aggregatorV3MockContract, oracleHeartbeat)).revertedWith("PriceCalculator: Oracle UpdatedAt Is Bad");
            })
        })
    })
})

async function prepareEnv() {
    const signers = await ethers.getSigners();
    const deployer = signers[0];
    const alice = signers[1];
    const bob = signers[2];

    const USD_DECIMALS = 18;
    const NATIVE_TOKEN_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

    const priceCalculatorFactory = await ethers.getContractFactory("PriceCalculator");
    const priceCalculatorContract = await priceCalculatorFactory.deploy();

    const aggregatorV3MockFactory = await ethers.getContractFactory("AggregatorV3Mock");
    const aggregatorV3MockContract = await aggregatorV3MockFactory.deploy();

    const oracleAnswer = 1;
    await aggregatorV3MockContract.setAnswer(oracleAnswer);

    const roundId = 1;
    await aggregatorV3MockContract.setRoundId(roundId);

    const erc20MockFactory = await ethers.getContractFactory("ERC20Mock");
    const erc20MockContract = await erc20MockFactory.deploy();

    return {
        deployer,
        alice,
        bob,

        USD_DECIMALS,
        NATIVE_TOKEN_ADDRESS,
        oracleAnswer,
        roundId,

        priceCalculatorContract,
        aggregatorV3MockContract,
        erc20MockContract
    };
}