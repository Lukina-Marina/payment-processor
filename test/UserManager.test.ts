import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

import { expect } from "chai";

describe("Unit tests for the AdminManager contract", () => {
    describe("Constructor", () => {
        it("Deployment tests", async () => {
            const env = await loadFixture(prepareEnv);
    
            expect(await env.userManagerContract.subscriptionManager()).equals(
                env.subscriptionManagerMockContract
            );
            expect(await env.userManagerContract.adminManager()).equals(
                env.adminManagerMockContract
            );
            expect(await env.userManagerContract.priceCalculator()).equals(
                env.priceCalculatorMockContract
            );
        });
    })

    describe("addSubscription function", () => {
        it("Main functionality", async () => {
            const env = await loadFixture(prepareEnvWithSubscriptionInfo);

            await env.subscriptionToken.connect(env.alice).mint(env.subscriptionAmount);
            await env.subscriptionToken.connect(env.alice).approve(env.userManagerContract, env.subscriptionAmount);

            const appId = env.appsLenght - 1;
            const subscriptionId = env.subscriptionLength - 1;

            const tx = env.userManagerContract.connect(env.alice).addSubscription(appId, subscriptionId, env.subscriptionToken);

            await expect(tx)
                .emit(env.userManagerContract, "AddedSubscription").withArgs(env.alice, appId, subscriptionId, 0, env.subscriptionToken);

            const awaitedTx = (await (await tx).wait())!;

            expect(await env.userManagerContract.activeSubscriptionsLength(env.alice)).equals(1);
            const activeSubscriptionInfo = await env.userManagerContract.activeSubscription(env.alice, 0);
            expect(activeSubscriptionInfo.appId).equals(appId);
            expect(activeSubscriptionInfo.subscriptionId).equals(subscriptionId);
            expect(activeSubscriptionInfo.subscriptionEndTime).equals((await awaitedTx.getBlock()).timestamp + env.subscriptionInfo.subscriptionPeriod);
            expect(activeSubscriptionInfo.token).equals(env.subscriptionToken);

            expect(await env.subscriptionToken.balanceOf(env.alice)).equals(0);

            const transferAmount = await env.subscriptionToken.balanceOf(env.protocolFeeReceiver) + await env.subscriptionToken.balanceOf(env.subscriptionInfo.reciever);
            expect(transferAmount).equals(env.subscriptionAmount);
        })

        it("Several active subscriptions with different appIds and subscriptionIds", async () => {
            const env = await loadFixture(prepareEnvWithSubscriptionInfo);

            const subscriptionInfo2 = {
                name: "name",
                amounts: [env.subscriptionAmount * 2n],
                subscriptionPeriod: 86400,
                reciever: env.subscriptionFeeReceiver,
                tokens: [env.subscriptionToken],
                isPaused: false
            };
            const subscriptionAmount2 = subscriptionInfo2.amounts[0];

            await env.subscriptionToken.connect(env.alice).mint(env.subscriptionAmount + subscriptionAmount2);
            await env.subscriptionToken.connect(env.alice).approve(env.userManagerContract, env.subscriptionAmount + subscriptionAmount2);

            const appId = env.appsLenght - 1;
            const subscriptionId = env.subscriptionLength - 1;

            await env.userManagerContract.connect(env.alice).addSubscription(appId, subscriptionId, env.subscriptionToken);
            await env.userManagerContract.connect(env.alice).addSubscription(appId, subscriptionId - 1, env.subscriptionToken);
            await env.userManagerContract.connect(env.alice).addSubscription(appId - 1, subscriptionId - 1, env.subscriptionToken);
        })

        describe("Reverts", () => {
            it("The same subscription twice", async () => {
                const env = await loadFixture(prepareEnvWithSubscriptionInfo);

                await env.subscriptionToken.connect(env.alice).mint(env.subscriptionAmount);
                await env.subscriptionToken.connect(env.alice).approve(env.userManagerContract, env.subscriptionAmount);

                const appId = env.appsLenght - 1;
                const subscriptionId = env.subscriptionLength - 1;

                await env.userManagerContract.connect(env.alice).addSubscription(appId, subscriptionId, env.subscriptionToken);
                await expect(env.userManagerContract.connect(env.alice).addSubscription(appId, subscriptionId, env.subscriptionToken)).revertedWith("UserManager: You have already subscribed");
            })

            it("Bad appId or subscriptionId", async () => {
                const env = await loadFixture(prepareEnvWithSubscriptionInfo);

                await expect(env.userManagerContract.connect(env.alice).addSubscription(env.appsLenght, env.subscriptionLength, env.subscriptionToken)).revertedWith("UserManager: Wrong appId");
                await expect(env.userManagerContract.connect(env.alice).addSubscription(env.appsLenght - 1, env.subscriptionLength, env.subscriptionToken)).revertedWith("UserManager: Wrong subscriptionId");
            })

            it("Bad appId or subscriptionId", async () => {
                const env = await loadFixture(prepareEnvWithSubscriptionInfo);

                await expect(env.userManagerContract.connect(env.alice).addSubscription(env.appsLenght - 1, env.subscriptionLength - 1, env.alice)).revertedWith("UserManager: No such token");
            })
        })
    })

    describe("cancelSubscription function", () => {
        it("Main functionality (delete first)", async () => {
            const env = await loadFixture(prepareEnvWithActiveSubscription);

            const anotherActiveSubscriptionInfoBefore = await env.userManagerContract.activeSubscription(env.user, 1);

            await expect(env.userManagerContract.connect(env.user).cancelSubscription(0))
                .emit(env.userManagerContract, "CanceledSubscription");

            expect(await env.userManagerContract.activeSubscriptionsLength(env.user)).equals(1);
            const anotherActiveSubscriptionInfoAfter = await env.userManagerContract.activeSubscription(env.user, 0);
            expect(anotherActiveSubscriptionInfoAfter.appId).equals(env.appId2);
            expect(anotherActiveSubscriptionInfoAfter.subscriptionId).equals(env.subscriptionId2);
            expect(anotherActiveSubscriptionInfoAfter.subscriptionEndTime).equals(anotherActiveSubscriptionInfoBefore.subscriptionEndTime);
            expect(anotherActiveSubscriptionInfoAfter.token).equals(anotherActiveSubscriptionInfoBefore.token);
        })

        it("Main functionality (delete second)", async () => {
            const env = await loadFixture(prepareEnvWithActiveSubscription);

            const anotherActiveSubscriptionInfoBefore = await env.userManagerContract.activeSubscription(env.user, 0);

            await expect(env.userManagerContract.connect(env.user).cancelSubscription(1))
                .emit(env.userManagerContract, "CanceledSubscription");

            expect(await env.userManagerContract.activeSubscriptionsLength(env.user)).equals(1);
            const anotherActiveSubscriptionInfoAfter = await env.userManagerContract.activeSubscription(env.user, 0);
            expect(anotherActiveSubscriptionInfoAfter.appId).equals(env.appId);
            expect(anotherActiveSubscriptionInfoAfter.subscriptionId).equals(env.subscriptionId);
            expect(anotherActiveSubscriptionInfoAfter.subscriptionEndTime).equals(anotherActiveSubscriptionInfoBefore.subscriptionEndTime);
            expect(anotherActiveSubscriptionInfoAfter.token).equals(anotherActiveSubscriptionInfoBefore.token);
        })
    })

    describe("changePaymentToken function", () => {
        it("Main functionality", async () => {
            const env = await loadFixture(prepareEnvWithActiveSubscription);

            const erc20MockContract2 = await env.erc20MockFactory.deploy();

            env.subscriptionInfo.tokens.push(erc20MockContract2);
            await env.subscriptionManagerMockContract.setSubscription(env.subscriptionInfo);
            env.subscriptionInfo.tokens.pop();

            await expect(env.userManagerContract.connect(env.user).changePaymentToken(0, erc20MockContract2))
                .emit(env.userManagerContract, "PaymentTokenChanged")
                .withArgs(env.user, env.subscriptionToken, erc20MockContract2, 0);

            const activeSubscriptionInfo = await env.userManagerContract.activeSubscription(env.user, 0);
            expect(activeSubscriptionInfo.token).equals(erc20MockContract2);
        })

        describe("Reverts", () => {
            it("Bad new token", async () => {
                const env = await loadFixture(prepareEnvWithActiveSubscription);

                const erc20MockContract2 = await env.erc20MockFactory.deploy();

                await expect(env.userManagerContract.connect(env.user).changePaymentToken(0, erc20MockContract2))
                    .revertedWith("UserManager: No such token");
            })
        })
    })

    it("changeSubscriptionInApp function", async () => {
        const env = await loadFixture(prepareEnvWithActiveSubscription);

        const newSubscriptionId = env.subscriptionId - 1;

        await env.subscriptionToken.connect(env.user).mint(env.subscriptionAmount);
        await env.subscriptionToken.connect(env.user).approve(env.userManagerContract, env.subscriptionAmount);

        await expect(env.userManagerContract.connect(env.user).changeSubscriptionInApp(0, newSubscriptionId))
            .emit(env.userManagerContract, "CanceledSubscription")
            .emit(env.userManagerContract, "AddedSubscription")
            .withArgs(env.user, env.appId, newSubscriptionId, 1, env.subscriptionToken);
    })

    describe("isActiveSubscription function", () => {
        it("Subscription is paused", async () => {
            const env = await loadFixture(prepareEnvWithActiveSubscription);

            expect(await env.userManagerContract.isActiveSubscription(env.user, 0)).true;

            env.subscriptionInfo.isPaused = true;
            await env.subscriptionManagerMockContract.setSubscription(env.subscriptionInfo);

            expect(await env.userManagerContract.isActiveSubscription(env.user, 0)).false;
        })

        it("Subscription is ended", async () => {
            const env = await loadFixture(prepareEnvWithActiveSubscription);

            expect(await env.userManagerContract.isActiveSubscription(env.user, 0)).true;

            const activeSubscriptionInfo = await env.userManagerContract.activeSubscription(env.user, 0);
            await time.increaseTo(activeSubscriptionInfo.subscriptionEndTime);

            expect(await env.userManagerContract.isActiveSubscription(env.user, 0)).false;
        })
    })

    describe("renewSubscription function", () => {
        it("Main functionaliy", async () => {
            const env = await loadFixture(prepareEnvWithActiveSubscription);

            const activeSubscriptionInfo = await env.userManagerContract.activeSubscription(env.user, 0);

            await env.subscriptionToken.connect(env.user).mint(env.subscriptionAmount);
            await env.subscriptionToken.connect(env.user).approve(env.userManagerContract, env.subscriptionAmount);

            const protocolFeeReceiverBalanceBefore = await env.subscriptionToken.balanceOf(env.protocolFeeReceiver);
            const subscriptionFeeReceiverBalanceBefore = await env.subscriptionToken.balanceOf(env.subscriptionFeeReceiver);

            await time.setNextBlockTimestamp(activeSubscriptionInfo.subscriptionEndTime);

            const tx = env.userManagerContract.renewSubscription(env.user, 0);
            await expect(tx).emit(env.userManagerContract, "RenewedSubscription");

            const protocolFeeReceiverBalanceAfter = await env.subscriptionToken.balanceOf(env.protocolFeeReceiver);
            const subscriptionFeeReceiverBalanceAfter = await env.subscriptionToken.balanceOf(env.subscriptionFeeReceiver);

            const serviceFeeAmount = env.subscriptionAmount * env.serviceFee / env.PERCENT_DENOMINATOR;
            const totalFeeAmount = protocolFeeReceiverBalanceAfter - protocolFeeReceiverBalanceBefore;
            const transactionFeeAmountToken = (totalFeeAmount - serviceFeeAmount);
            const transactionFeeAmount = transactionFeeAmountToken / env.price;

            await expect(tx).emit(env.userManagerContract, "FeeCharged").withArgs(env.subscriptionToken, serviceFeeAmount, transactionFeeAmount, transactionFeeAmountToken);

            expect(subscriptionFeeReceiverBalanceAfter - subscriptionFeeReceiverBalanceBefore).equals(env.subscriptionAmount - totalFeeAmount);

            const awaitedTx = (await (await tx).wait())!;
            const renewTimestamp = (await awaitedTx.getBlock()).timestamp;
            const activeSubscriptionInfoNew = await env.userManagerContract.activeSubscription(env.user, 0);
            expect(activeSubscriptionInfoNew.subscriptionEndTime).equals(renewTimestamp + env.subscriptionInfo.subscriptionPeriod);
        })

        describe("Reverts", () => {
            it("Protocol is paused", async () => {
                const env = await loadFixture(prepareEnvWithActiveSubscription);

                await env.adminManagerMockContract.setIsPaused(true);

                await expect(env.userManagerContract.renewSubscription(env.user, 0)).revertedWith("UserManager: Paused");
            })

            it("Subscription is active", async () => {
                const env = await loadFixture(prepareEnvWithActiveSubscription);

                await expect(env.userManagerContract.renewSubscription(env.user, 0)).revertedWith("UserManager: Subscription is active");
            })

            it("Subscription is paused", async () => {
                const env = await loadFixture(prepareEnvWithActiveSubscription);

                env.subscriptionInfo.isPaused = true;
                await env.subscriptionManagerMockContract.setSubscription(env.subscriptionInfo);
                env.subscriptionInfo.isPaused = false;

                await expect(env.userManagerContract.renewSubscription(env.user, 0)).revertedWith("UserManager: Subscription is paused");
            })

            it("Bad token", async () => {
                const env = await loadFixture(prepareEnvWithActiveSubscription);

                const erc20MockContract2 = await env.erc20MockFactory.deploy();

                env.subscriptionInfo.tokens[0] = erc20MockContract2;
                await env.subscriptionManagerMockContract.setSubscription(env.subscriptionInfo);
                env.subscriptionInfo.tokens[0] = env.subscriptionToken;

                const activeSubscriptionInfo = await env.userManagerContract.activeSubscription(env.user, 0);

                await time.increaseTo(activeSubscriptionInfo.subscriptionEndTime);

                await expect(env.userManagerContract.renewSubscription(env.user, 0)).revertedWith("UserManager: No such token");
            })

            it("Too big total fee", async () => {
                const env = await loadFixture(prepareEnvWithActiveSubscription);

                const activeSubscriptionInfo = await env.userManagerContract.activeSubscription(env.user, 0);
                await time.increaseTo(activeSubscriptionInfo.subscriptionEndTime);

                await env.priceCalculatorMockContract.setPrice(ethers.WeiPerEther);

                await expect(env.userManagerContract.renewSubscription(env.user, 0)).revertedWith("UserManager: Too big fee");
            })
        })
    })
});

async function prepareEnvWithActiveSubscription() {
    const env = await loadFixture(prepareEnvWithSubscriptionInfo);

    const user = env.alice;
    const appId = env.appsLenght - 1;
    const subscriptionId = env.subscriptionLength - 1;
    const appId2 = appId - 1;
    const subscriptionId2 = subscriptionId - 1;

    await env.subscriptionToken.connect(user).mint(env.subscriptionAmount * 2n);
    await env.subscriptionToken.connect(user).approve(env.userManagerContract, env.subscriptionAmount * 2n);

    await env.userManagerContract.connect(user).addSubscription(appId, subscriptionId, env.subscriptionToken);
    await env.userManagerContract.connect(user).addSubscription(appId2, subscriptionId2, env.subscriptionToken);

    return {
        ...env,

        user,
        appId,
        subscriptionId,
        appId2,
        subscriptionId2
    }
}

async function prepareEnvWithSubscriptionInfo() {
    const env = await loadFixture(prepareEnv);

    const erc20MockFactory = await ethers.getContractFactory("ERC20Mock");
    const erc20MockContract = await erc20MockFactory.deploy();

    const subscriptionInfo = {
        name: "name",
        amounts: [ethers.WeiPerEther * 2n],
        subscriptionPeriod: 86400,
        reciever: env.subscriptionFeeReceiver,
        tokens: [erc20MockContract],
        isPaused: false
    };
    const subscriptionAmount = subscriptionInfo.amounts[0];
    const subscriptionToken = subscriptionInfo.tokens[0];

    const appsLenght = 4;
    const subscriptionLength = appsLenght + 1;

    await env.subscriptionManagerMockContract.setSubscription(subscriptionInfo);
    await env.subscriptionManagerMockContract.setAppsLenght(appsLenght);
    await env.subscriptionManagerMockContract.setSubscriptionLength(subscriptionLength);

    return {
        ...env,

        subscriptionInfo,
        subscriptionAmount,
        subscriptionToken,

        appsLenght,
        subscriptionLength,

        erc20MockFactory
    };
}

async function prepareEnv() {
    const signers = await ethers.getSigners();
    const deployer = signers[0];
    const subscriptionFeeReceiver = signers[1];
    const protocolFeeReceiver = signers[2];
    const alice = signers[3];
    const bob = signers[4];

    const serviceFee = 30n;
    const extraGasAmount = 50_000n;
    const PERCENT_DENOMINATOR = 10000n;

    const subscriptionManagerMockFactory = await ethers.getContractFactory("SubscriptionManagerMock");
    const subscriptionManagerMockContract = await subscriptionManagerMockFactory.deploy();

    const adminManagerMockFactory = await ethers.getContractFactory("AdminManagerMock");
    const adminManagerMockContract = await adminManagerMockFactory.deploy();

    await adminManagerMockContract.setServiceFee(serviceFee);
    await adminManagerMockContract.setExtraGasAmount(extraGasAmount);
    await adminManagerMockContract.setFeeReceiver(protocolFeeReceiver);

    const priceCalculatorMockFactory = await ethers.getContractFactory("PriceCalculatorMock");
    const priceCalculatorMockContract = await priceCalculatorMockFactory.deploy();

    const price = 2n;
    await priceCalculatorMockContract.setPrice(price);

    const userManagerFactory = await ethers.getContractFactory("UserManager");
    const userManagerContract = await userManagerFactory.deploy(subscriptionManagerMockContract, adminManagerMockContract, priceCalculatorMockContract);


    return {
        deployer,
        subscriptionFeeReceiver,
        protocolFeeReceiver,
        alice,
        bob,

        serviceFee,
        extraGasAmount,
        PERCENT_DENOMINATOR,
        price,

        subscriptionManagerMockContract,
        adminManagerMockContract,
        priceCalculatorMockContract,
        userManagerContract  
    };
}
