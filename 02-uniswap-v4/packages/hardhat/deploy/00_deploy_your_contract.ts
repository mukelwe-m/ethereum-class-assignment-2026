import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

// Import external build artifacts to deploy mock Uniswap infrastructure locally
import poolManagerArtifact from "@uniswap/v4-core/out/PoolManager.sol/PoolManager.json";
import positionManagerArtifact from "@uniswap/v4-periphery/foundry-out/PositionManager.sol/PositionManager.json";
import positionDescriptorArtifact from "@uniswap/v4-periphery/foundry-out/PositionDescriptor.sol/PositionDescriptor.json";

const deployYourContracts: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  console.log("\n====================================================");
  console.log(`Starting Scaffold Pipeline with Account: ${deployer}`);
  console.log("====================================================\n");

  const INITIAL_SUPPLY = hre.ethers.parseUnits("1000000", 18);

  // ------------------------------------------------------------------------
  // PART 1: Core Reward Assets & Order Book System
  // ------------------------------------------------------------------------

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

  // 3. Deploy OrderBook
  await deploy("OrderBook", {
    from: deployer,
    args: [pnpToken.address, fnbToken.address],
    log: true,
    autoMine: true,
  });

  // ------------------------------------------------------------------------
  // PART 2: Uniswap v4 Infrastructure Mocks (For Local Verification)
  // ------------------------------------------------------------------------
  console.log("\n⏳ Deploying Uniswap v4 local infrastructure...");

  // 4. Deploy PoolManager using external JSON artifact specs
  const poolManager = await deploy("PoolManager", {
    from: deployer,
    contract: {
      abi: poolManagerArtifact.abi,
      bytecode: typeof poolManagerArtifact.bytecode === "string" 
        ? poolManagerArtifact.bytecode 
        : poolManagerArtifact.bytecode.object,
    },
    args: [deployer],
    log: true,
    autoMine: true,
  });

  // 5. Deploy Mock Permit2 Required by V4 routers
  const mockPermit2 = await deploy("MockPermit2", {
    from: deployer,
    log: true,
    autoMine: true,
  });

  // 6. Deploy Mock WETH9 for wrapped native pricing mechanics
  const mockWeth = await deploy("MockWETH9", {
    from: deployer,
    log: true,
    autoMine: true,
  });

  // 7. Deploy PositionDescriptor to render visual representations of positions
  const positionDescriptor = await deploy("PositionDescriptor", {
    from: deployer,
    contract: {
      abi: positionDescriptorArtifact.abi,
      bytecode: typeof positionDescriptorArtifact.bytecode === "string"
        ? positionDescriptorArtifact.bytecode
        : positionDescriptorArtifact.bytecode.object,
    },
    args: [poolManager.address, mockWeth.address, hre.ethers.encodeBytes32String("ETH")],
    log: true,
    autoMine: true,
  });

  // 8. Deploy PositionManager Router to manage liquidity entries/exits
  const positionManager = await deploy("PositionManager", {
    from: deployer,
    contract: {
      abi: positionManagerArtifact.abi,
      bytecode: typeof positionManagerArtifact.bytecode === "string"
        ? positionManagerArtifact.bytecode
        : positionManagerArtifact.bytecode.object,
    },
    args: [
      poolManager.address,
      mockPermit2.address,
      500_000n, // gas allowance parameter
      positionDescriptor.address,
      mockWeth.address,
    ],
    log: true,
    autoMine: true,
  });

  // ------------------------------------------------------------------------
  // PART 3: RewardTokensManager Integration
  // ------------------------------------------------------------------------
  console.log("\n⏳ Deploying Assignment RewardTokensManager...");

  // 9. Deploy the RewardTokensManager linking pool managers and asset assets
  await deploy("RewardTokensManager", {
    from: deployer,
    args: [
      poolManager.address,
      positionManager.address,
      pnpToken.address,
      fnbToken.address,
    ],
    log: true,
    autoMine: true,
  });

};

export default deployYourContracts;
deployYourContracts.tags = ["CompleteRewardSystem"];