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
