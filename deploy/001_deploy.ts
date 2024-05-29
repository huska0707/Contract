import { HardhatRuntimeEnvironment, Network } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, utils } from "ethers";
import { chainIdToAddresses } from "../networkVariables";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre; 
    const { deploy, execute } = deployments;
}