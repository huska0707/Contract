import dotenv from "dotenv";
dotenv.config();
import { parseEther } from "@ethersproject/units";

import { HardhatUserConfig } from "hardhat/types";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-abi-exporter";
import "hardhat-tracer";

const infuraApiKey = process.env.INFURA_API_KEY!;
const privateKey = process.env.DEPLOYER_PRIVATE_KEY!;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  namedAccounts: {
    deployer: 0,
  },
  defaultNetwork: "hardhat",
  networks: {
    local: {
      url: "http://127.0.0.1:8545",
      accounts: [privateKey!],
    },
    hardhat: {
      forking: {
        url: process.env.POLYGON_NODE_URL!,
      },
      accounts: [
        {
          privateKey: privateKey!,
          balance: parseEther("100").toString(),
        },
      ],
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${infuraApiKey}`,
      accounts: [privateKey],
    },
    polygon: {
      url: process.env.POLYGON_NODE_URL!,
      accounts: [privateKey!],
    },
    polygonTestnet: {
      url: process.env.POLYGON_TESTNET_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
    },
  },
  mocha: {
    timeout: 200000,
  },
};

export default config;
