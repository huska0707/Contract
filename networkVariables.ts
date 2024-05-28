import { ethers } from "ethers";

interface ChainAddresses {
  [contractName: string]: string;
}

const chainIds = {
  ganache: 5777,
  goerli: 5,
  hardhat: 7545,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  bscTestnet: 97,
  bscMainnet: 56,
  MaticTestnet: 80001,
  MaticMainnet: 137,
  ropsten: 3,
};

export const KovanTestnet: ChainAddresses = {
  keeperRegistryAddress: "0x4Cb093f226983713164A62138C3F718A5b595F73",
  vrfCoordinatorAddress: "0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9",
  linkTokenAddress: "0xa36085F69e2889c224210F603D836748e7dC0088",
  VRFKeyHash:
    "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4",
  VRFFee: ethers.utils.parseEther("0.1").toString(),
};

export const MaticTestnet: ChainAddresses = {
  keeperRegistryAddress: "0x6179B349067af80D0c171f43E6d767E4A00775Cd",
  vrfCoordinatorAddress: "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255",
  linkTokenAddress: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
  VRFKeyHash:
    "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4",
  VRFFee: ethers.utils.parseEther("0.0001").toString(),
};

export const chainIdToAddresses: {
  [id: number]: { [contractName: string]: string };
} = {
  [chainIds.kovan]: { ...KovanTestnet },
  [chainIds.MaticTestnet]: { ...MaticTestnet },
};
