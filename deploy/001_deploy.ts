import { HardhatRuntimeEnvironment, Network } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, utils } from "ethers";
import { chainIdToAddresses } from "../networkVariables";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre; 
    const { deploy, execute } = deployments;

    const { deployer } = await getNamedAccounts(); 
    const chainId = parseInt(await hre.getChainId()); 
    const addresses = chainIdToAddresses[chainId];

    const socialLegoToken = await deploy("SocialLegoToken", {
        from: deployer, // Deployer's address
        log: true, // Enable logging
      });
}