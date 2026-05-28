import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployYourContracts: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const INITIAL_SUPPLY = hre.ethers.parseUnits("1000000", 18);

  // 1. Deploy PNPToken (Passes the required initial supply argument)
  const pnpToken = await deploy("PNPToken", {
    from: deployer,
    args: [INITIAL_SUPPLY],
    log: true,
    autoMine: true,
  });

  // 2. Deploy FNBToken (Passes the required initial supply argument)
  const fnbToken = await deploy("FNBToken", {
    from: deployer,
    args: [INITIAL_SUPPLY],
    log: true,
    autoMine: true,
  });

  // 3. Deploy OrderBook (Passes the deployed token addresses to the constructor)
  await deploy("OrderBook", {
    from: deployer,
    args: [pnpToken.address, fnbToken.address],
    log: true,
    autoMine: true,
  });

  console.log("All contracts deployed successfully and synced with frontend types!");
};

export default deployYourContracts;
deployYourContracts.tags = ["OrderBookSystem"];