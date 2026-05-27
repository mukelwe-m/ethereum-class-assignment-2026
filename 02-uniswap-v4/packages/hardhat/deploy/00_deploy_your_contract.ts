import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployAssignmentContracts: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // 1M tokens with 18 decimals (matches what your test expects)
  const INITIAL_SUPPLY = "1000000000000000000000000"; 

  console.log("🚀 Starting deployment with account:", deployer);

  // 1. Deploy PNPToken
  const pnpToken = await deploy("PNPToken", {
    from: deployer,
    args: [INITIAL_SUPPLY],
    log: true,
    autoMine: true,
  });

  // 2. Deploy FNBToken
  const fnbToken = await deploy("FNBToken", {
    from: deployer,
    args: [INITIAL_SUPPLY],
    log: true,
    autoMine: true,
  });

  // 3. Deploy OrderBook using the addresses of the two tokens
  await deploy("OrderBook", {
    from: deployer,
    args: [pnpToken.address, fnbToken.address],
    log: true,
    autoMine: true,
  });

  console.log("✅ All assignment contracts deployed successfully!");
};

export default deployAssignmentContracts;

deployAssignmentContracts.tags = ["Assignment"];