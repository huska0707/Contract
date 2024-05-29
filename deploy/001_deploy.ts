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

      const socialLego = await deploy("SocialLego", {
        args: [addresses.keeperRegistryAddress], // Constructor arguments
        from: deployer, // Deployer's address
        log: true, // Enable logging
      });

      const nftMint = await deploy("NFTMint", {
        args: [
          addresses.vrfCoordinatorAddress, // VRF coordinator address
          addresses.linkTokenAddress, // LINK token address
          addresses.VRFKeyHash, // VRF key hash
          addresses.VRFFee, // VRF fee
          addresses.keeperRegistryAddress, // Keeper registry address
        ],
        from: deployer, // Deployer's address
        log: true, // Enable logging
      });

      const breakInGame = await deploy("BreakInGame", {
        args: [
          addresses.vrfCoordinatorAddress, // VRF coordinator address
          addresses.linkTokenAddress, // LINK token address
          addresses.VRFKeyHash, // VRF key hash
          addresses.VRFFee, // VRF fee
          addresses.keeperRegistryAddress, // Keeper registry address
          nftMint.address, // NFTMint contract address
          socialLegoToken.address, // SocialLegoToken contract address
        ],
        from: deployer, // Deployer's address
        log: true, // Enable logging
      });

      await execute(
        "NFTMint", // Contract to interact with
        {
          from: deployer, // Deployer's address
          log: true, // Enable logging
        },
        "changeGameAddress", // Function to call
        breakInGame.address // New game address
      );
      const socialLegoStore = await deploy("onlineStore", {
        args: [addresses.keeperRegistryAddress, socialLegoToken.address], // Constructor arguments
        from: deployer, // Deployer's address
        log: true, // Enable logging
      });
}