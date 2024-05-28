import { HardhatUserConfig } from "hardhat/types";

import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-verify";

import "@typechain/ethers-v6";
import "@typechain/hardhat";

import "hardhat-abi-exporter";
import "hardhat-spdx-license-identifier";

import "solidity-coverage";

const hardhatConfig: HardhatUserConfig = {
    networks: {},
    solidity: {
        compilers: [
            {
                version: "0.8.24",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                    evmVersion: "paris",
                },
            },
        ],
    },

    mocha: {
        timeout: 1000000,
    },

    // EXTENSIONS

    etherscan: {
        // list networks: npx hardhat verify --list-networks
        apiKey: {
            // mainnet: "API_KEY"
        },
    },

    typechain: {
        target: "ethers-v6",
    },

    spdxLicenseIdentifier: {
        overwrite: true,
        runOnCompile: true,
    },

    abiExporter: {
        path: "./abi",
        runOnCompile: true,
        clear: true,
        flat: true,
        spacing: 2,
        except: [
            "@openzeppelin/contracts/",
            "@openzeppelin/contracts-upgradeable/",
            "interfaces/",
            "mocks/",
        ],
    },
};
export default hardhatConfig;
