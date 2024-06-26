import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

import { expect } from "chai";

describe("Unit tests for the AdminManager contract", () => {
    it("Deployment tests", async () => {
        const env = await loadFixture(prepareEnv);

        expect(await env.subscriptionManagerContract.appsLenght()).equals(
            0
        );
    });

    it("addApp function", async () => {
        const env = await loadFixture(prepareEnv);

        const name = "name";
        const description = "description";

        await expect(env.subscriptionManagerContract.connect(env.alice).addApp(name, description)).emit(
            env.subscriptionManagerContract, "AppAdded"
        ).withArgs(env.alice, 0, name, description);

        const appInfo = await env.subscriptionManagerContract.apps(0);
        expect(appInfo.owner).equals(
            env.alice
        );
        expect(appInfo.subscriptions.length).equals(0);
        expect(appInfo.name).equals(name);
        expect(appInfo.description).equals(description);
    })

    describe("addSubscription function", () => {
        it("Main functionality", async () => {
            const env = await loadFixture(prepareEnvWithApp);
        
            const subscriptionInfo = {
                name: "name",
                amounts: [1, 2],
                subscriptionPeriod: 2,
                reciever: env.alice,
                tokens: [env.bob, env.alice],
                isPaused: false
            };

            await expect(env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, subscriptionInfo)).emit(
                env.subscriptionManagerContract, "SubscriptionAdded"
            );
            
            expect(await env.subscriptionManagerContract.subscriptionLength(0)).equals(1);
            const subscriptionInfoResult = await env.subscriptionManagerContract.subscription(0, 0);
            expect(subscriptionInfoResult.name).equals(subscriptionInfo.name);
            expect(subscriptionInfoResult.amounts.length).equals(2);
            expect(subscriptionInfoResult.amounts[0]).equals(subscriptionInfo.amounts[0]);
            expect(subscriptionInfoResult.amounts[1]).equals(subscriptionInfo.amounts[1]);
            expect(subscriptionInfoResult.subscriptionPeriod).equals(subscriptionInfo.subscriptionPeriod);
            expect(subscriptionInfoResult.reciever).equals(subscriptionInfo.reciever);
            expect(subscriptionInfoResult.tokens.length).equals(2);
            expect(subscriptionInfoResult.tokens[0]).equals(subscriptionInfo.tokens[0]);
            expect(subscriptionInfoResult.tokens[1]).equals(subscriptionInfo.tokens[1]);
            expect(subscriptionInfoResult.isPaused).equals(subscriptionInfo.isPaused);
        })

        describe("Reverts", () => {
            it("Owner test", async () => {
                const env = await loadFixture(prepareEnvWithApp);

                await expect(
                    env.subscriptionManagerContract.connect(env.bob).addSubscription(0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: caller is not the owner");
            })

            it("Length test", async () => {
                const env = await loadFixture(prepareEnvWithApp);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, {
                        name: "name",
                        amounts: [1, 1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: different length");

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob, env.deployer],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: different length");
            })

            it("Reciever test", async () => {
                const env = await loadFixture(prepareEnvWithApp);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 2,
                        reciever: ethers.ZeroAddress,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: reciever is zero");
            })

            it("SubscriptionPeriod test", async () => {
                const env = await loadFixture(prepareEnvWithApp);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 0,
                        reciever: env.alice,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: subscriptionPeriod is zero");
            })

            it("Zero token test", async () => {
                const env = await loadFixture(prepareEnvWithApp);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [ethers.ZeroAddress],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: token is zero");
            })

            it("Zero amount test", async () => {
                const env = await loadFixture(prepareEnvWithApp);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, {
                        name: "name",
                        amounts: [0],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: amount is zero");
            })

            it("Equil tokens test", async () => {
                const env = await loadFixture(prepareEnvWithApp);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, {
                        name: "name",
                        amounts: [1, 1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob, env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: equil tokens");
            })
        })
    })

    describe("changeSubscription function", () => {
        it("Main functionality", async () => {
            const env = await loadFixture(prepareEnvWithAppAndSubscription);
        
            const newSubscriptionInfo = {
                name: "newName",
                amounts: [2],
                subscriptionPeriod: 3,
                reciever: env.bob,
                tokens: [env.alice],
                isPaused: true
            };

            await expect(env.subscriptionManagerContract.connect(env.appOwner).changeSubscription(0, 0, newSubscriptionInfo)).emit(
                env.subscriptionManagerContract, "SubscriptionChanged"
            );
            
            expect(await env.subscriptionManagerContract.subscriptionLength(0)).equals(1);
            const subscriptionInfoResult = await env.subscriptionManagerContract.subscription(0, 0);
            expect(subscriptionInfoResult.name).equals(newSubscriptionInfo.name);
            expect(subscriptionInfoResult.amounts.length).equals(1);
            expect(subscriptionInfoResult.amounts[0]).equals(newSubscriptionInfo.amounts[0]);
            expect(subscriptionInfoResult.subscriptionPeriod).equals(newSubscriptionInfo.subscriptionPeriod);
            expect(subscriptionInfoResult.reciever).equals(newSubscriptionInfo.reciever);
            expect(subscriptionInfoResult.tokens.length).equals(1);
            expect(subscriptionInfoResult.tokens[0]).equals(newSubscriptionInfo.tokens[0]);
            expect(subscriptionInfoResult.isPaused).equals(newSubscriptionInfo.isPaused);
        })

        describe("Reverts", () => {
            it("Owner test", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.bob).changeSubscription(0, 0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: caller is not the owner");
            })

            it("Length test", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).changeSubscription(0, 0, {
                        name: "name",
                        amounts: [1, 1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: different length");

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).changeSubscription(0, 0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob, env.deployer],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: different length");
            })

            it("Reciever test", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).changeSubscription(0, 0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 2,
                        reciever: ethers.ZeroAddress,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: reciever is zero");
            })

            it("SubscriptionPeriod test", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).changeSubscription(0, 0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 0,
                        reciever: env.alice,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: subscriptionPeriod is zero");
            })

            it("Zero token test", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).changeSubscription(0, 0, {
                        name: "name",
                        amounts: [1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [ethers.ZeroAddress],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: token is zero");
            })

            it("Zero amount test", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).changeSubscription(0, 0, {
                        name: "name",
                        amounts: [0],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: amount is zero");
            })

            it("Equil tokens test", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.appOwner).changeSubscription(0, 0, {
                        name: "name",
                        amounts: [1, 1],
                        subscriptionPeriod: 2,
                        reciever: env.alice,
                        tokens: [env.bob, env.bob],
                        isPaused: false
                    })
                ).revertedWith("SubscriptionManager: equil tokens");
            })
        })
    })

    describe("PauseSubscription and UnpauseSubscription functionality", () => {
        it("Pause and then unpause", async () => {
            const env = await loadFixture(prepareEnvWithAppAndSubscription);

            await expect(env.subscriptionManagerContract.connect(env.alice).pauseSubscription(0, 0)).emit(
                env.subscriptionManagerContract, "SubscriptionPaused"
            ).withArgs(env.alice, 0, 0);

            const subscriptionInfoAfterPause = await env.subscriptionManagerContract.subscription(0, 0);
            expect(subscriptionInfoAfterPause.isPaused).equal(
                true
            );

            await expect(env.subscriptionManagerContract.connect(env.alice).unpauseSubscription(0, 0)).emit(
                env.subscriptionManagerContract, "SubscriptionUnpaused"
            ).withArgs(env.alice, 0, 0);

            const subscriptionInfoAfterUnpause = await env.subscriptionManagerContract.subscription(0, 0);
            expect(subscriptionInfoAfterUnpause.isPaused).equal(
                false
            );
        })

        describe("Reverts", () => {
            it("Only owner pause function", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.bob).pauseSubscription(0, 0)
                ).revertedWith("SubscriptionManager: caller is not the owner");
            })

            it("Only owner unpause function", async () => {
                const env = await loadFixture(prepareEnvWithAppAndSubscription);

                await expect(
                    env.subscriptionManagerContract.connect(env.bob).unpauseSubscription(0, 0)
                ).revertedWith("SubscriptionManager: caller is not the owner");
            })
        })
    })
});

async function prepareEnvWithAppAndSubscription() {
    const env = await loadFixture(prepareEnvWithApp);

    const subscriptionInfo = {
        name: "name",
        amounts: [1],
        subscriptionPeriod: 2,
        reciever: env.alice,
        tokens: [env.bob],
        isPaused: false
    };

    await env.subscriptionManagerContract.connect(env.appOwner).addSubscription(0, subscriptionInfo);

    return {
        ...env,

        subscriptionInfo,
    };
}

async function prepareEnvWithApp() {
    const env = await loadFixture(prepareEnv);

    const appOwner = env.alice;
    const appName = "name";
    const addDescription = "description";

    await env.subscriptionManagerContract.connect(appOwner).addApp(appName, addDescription);

    return {
        ...env,

        appOwner,
        appName,
        addDescription
    };
}

async function prepareEnv() {
    const signers = await ethers.getSigners();
    const deployer = signers[0];
    const feeReceiver = signers[1];
    const alice = signers[2];
    const bob = signers[3];

    const subscriptionManagerFactory = await ethers.getContractFactory("SubscriptionManager");
    const subscriptionManagerContract = await subscriptionManagerFactory.deploy();

    return {
        deployer,
        feeReceiver,
        alice,
        bob,

        subscriptionManagerContract
    };
}