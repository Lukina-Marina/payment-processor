import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

import { expect } from "chai";

describe("Unit tests for the AdminManager contract", () => {
    it("Deployment tests", async () => {
        const env = await loadFixture(prepareEnv);

        expect(await env.adminManagerContract.serviceFee()).equals(
            env.serviceFee
        );
        expect(await env.adminManagerContract.feeReceiver()).equals(
            env.feeReceiver
        );
        expect(await env.adminManagerContract.extraGasAmount()).equals(
            env.extraGasAmount
        );
    });

    describe("setServiceFee function", () => {
        it("Main functionality", async () => {
            const env = await loadFixture(prepareEnv);

            const newServiceFee = env.serviceFee + 1_00;
            await expect(
                env.adminManagerContract.setServiceFee(newServiceFee)
            ).emit(
                env.adminManagerContract, "ServiceFeeChanged"
            ).withArgs(env.serviceFee, newServiceFee);

            expect(await env.adminManagerContract.serviceFee()).equals(
                newServiceFee
            );
        })

        describe("Reverts", () => {
            it("Only owner test", async () => {
                const env = await loadFixture(prepareEnv);

                await expect(
                    env.adminManagerContract.connect(env.bob).setServiceFee(0)
                ).revertedWith("Ownable: caller is not the owner");
            })

            it("Bad newServiceFee", async () => {
                const env = await loadFixture(prepareEnv);
                    
                await expect(
                    env.adminManagerContract.setServiceFee(env.PERCENT_DENOMINATOR)
                ).revertedWith("AdminManager: Too big service fee");
            })
        })
    })


    describe("setFeeReceiver function", () => {
        it("Main functionality", async () => {
            const env = await loadFixture(prepareEnv);

            const newFeeReceiver = env.alice;
            await expect(
                env.adminManagerContract.setFeeReceiver(newFeeReceiver)
            ).emit(
                env.adminManagerContract, "FeeReceiverChanged"
            ).withArgs(env.feeReceiver, newFeeReceiver);

            expect(await env.adminManagerContract.feeReceiver()).equals(
                newFeeReceiver
            );
        })

        describe("Reverts", () => {
            it("Only owner test", async () => {
                const env = await loadFixture(prepareEnv);

                await expect(
                    env.adminManagerContract.connect(env.bob).setFeeReceiver(ethers.ZeroAddress)
                ).revertedWith("Ownable: caller is not the owner");
            })

            it("Zero fee receiver", async () => {
                const env = await loadFixture(prepareEnv);
                    
                await expect(
                    env.adminManagerContract.setFeeReceiver(ethers.ZeroAddress)
                ).revertedWith("AdminManager: Zero fee receiver");
            })
        })
    })


    describe("setExtraGasAmount function", () => {
        it("Main functionality", async () => {
            const env = await loadFixture(prepareEnv);

            const newExtraGasAmount = env.extraGasAmount + 100;
            await expect(
                env.adminManagerContract.setExtraGasAmount(newExtraGasAmount)
            ).emit(
                env.adminManagerContract, "ExtraGasAmountChanged"
            ).withArgs(env.extraGasAmount, newExtraGasAmount);

            expect(await env.adminManagerContract.extraGasAmount()).equals(
                newExtraGasAmount
            );
        })

        describe("Reverts", () => {
            it("Only owner test", async () => {
                const env = await loadFixture(prepareEnv);

                await expect(
                    env.adminManagerContract.connect(env.bob).setExtraGasAmount(0)
                ).revertedWith("Ownable: caller is not the owner");
            })

            it("Bad ExtraGasAmount", async () => {
                const env = await loadFixture(prepareEnv);
                    
                await expect(
                    env.adminManagerContract.setExtraGasAmount(0)
                ).revertedWith("AdminManager: Zero extra gas amount");
            })
        })
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

    const adminManagerFactory = await ethers.getContractFactory("AdminManager");
    const adminManagerContract = await adminManagerFactory.deploy(serviceFee, feeReceiver, extraGasAmount);

    return {
        deployer,
        feeReceiver,
        alice,
        bob,

        serviceFee,
        extraGasAmount,
        PERCENT_DENOMINATOR,

        adminManagerContract
    };
}
