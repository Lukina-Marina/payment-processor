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
});

async function prepareEnv() {
    const signers = await ethers.getSigners();
    const deployer = signers[0];
    const feeReceiver = signers[1];
    const alice = signers[2];
    const bob = signers[3];

    const serviceFee = 30;
    const extraGasAmount = 50_000;
    const PERCENT_DENOMINATOR = 10000;

    const subscriptionManagerMockFactory = await ethers.getContractFactory("SubscriptionManagerMock");
    const subscriptionManagerMockContract = await subscriptionManagerMockFactory.deploy();

    const adminManagerMockFactory = await ethers.getContractFactory("AdminManagerMock");
    const adminManagerMockContract = await adminManagerMockFactory.deploy();

    const priceCalculatorMockFactory = await ethers.getContractFactory("PriceCalculatorMock");
    const priceCalculatorMockContract = await priceCalculatorMockFactory.deploy();

    const userManagerFactory = await ethers.getContractFactory("UserManager");
    const userManagerContract = await userManagerFactory.deploy(subscriptionManagerMockContract, adminManagerMockContract, priceCalculatorMockContract);


    return {
        deployer,
        feeReceiver,
        alice,
        bob,

        serviceFee,
        extraGasAmount,
        PERCENT_DENOMINATOR,

        subscriptionManagerMockContract,
        adminManagerMockContract,
        priceCalculatorMockContract,
        userManagerContract  
    };
}
