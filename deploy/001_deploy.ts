import { HardhatRuntimeEnvironment, Network } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, utils } from "ethers";
import { chainIdToAddresses } from "../networkVariables";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;

  const { deployer } = await getNamedAccounts();
  // get current chainId
  const chainId = parseInt(await hre.getChainId());
  const addresses = chainIdToAddresses[chainId];

  const socialLegoToken = await deploy("SocialLegoToken", {
    from: deployer,
    log: true,
  });

  const socialLego = await deploy("SocialLego", {
    args: [addresses.keeperRegistryAddress],
    from: deployer,
    log: true,
  });

  const nftMint = await deploy("NFTMint", {
    args: [
      addresses.vrfCoordinatorAddress,
      addresses.linkTokenAddress,
      addresses.VRFKeyHash,
      addresses.VRFFee,
      addresses.keeperRegistryAddress,
    ],
    from: deployer,
    log: true,
  });

  const breakInGame = await deploy("BreakInGame", {
    args: [
      addresses.vrfCoordinatorAddress,
      addresses.linkTokenAddress,
      addresses.VRFKeyHash,
      addresses.VRFFee,
      addresses.keeperRegistryAddress,
      nftMint.address,
      socialLegoToken.address,
    ],
    from: deployer,
    log: true,
  });
  await execute(
    "NFTMint",
    {
      from: deployer,
      log: true,
    },
    "changeGameAddress",
    breakInGame.address
  );

  const socialLegoStore = await deploy("onlineStore", {
    args: [addresses.keeperRegistryAddress, socialLegoToken.address],
    from: deployer,
    log: true,
  });
};
export default func;
func.tags = [
  "SocialLegoToken",
  "SocialLego",
  "NFTMint",
  "BreakInGame",
  "onlineStore",
];
