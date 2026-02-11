import { ethers } from "hardhat";

async function main() {
  console.log("Deploying LendingPool contract...");

  // Configuration
  const STABLECOIN_ADDRESS = process.env.STABLECOIN_ADDRESS || "0x..."; // USDT/USDC address
  const ADMIN_ADDRESS = process.env.ADMIN_ADDRESS || (await ethers.getSigners())[0].address;

  // Deploy
  const LendingPool = await ethers.getContractFactory("LendingPool");
  const lendingPool = await LendingPool.deploy(STABLECOIN_ADDRESS, ADMIN_ADDRESS);
  await lendingPool.waitForDeployment();

  const address = await lendingPool.getAddress();
  console.log(`✅ LendingPool deployed to: ${address}`);

  // Configure example pools
  console.log("\nConfiguring lending pools...");

  // Pool 1: 30 days, 10% APR
  await lendingPool.configurePool(
    1,
    "30-Day Pool",
    100, // Min reputation score
    500, // $500 loan
    1,   // Tier 1
    30 * 24 * 60 * 60, // 30 days in seconds
    10,  // 10% APR
    true
  );
  console.log("✅ Pool 1 configured: 30 days, 10% APR");

  // Pool 2: 90 days, 8% APR
  await lendingPool.configurePool(
    2,
    "90-Day Pool",
    200,
    1000,
    2,
    90 * 24 * 60 * 60, // 90 days
    8,
    true
  );
  console.log("✅ Pool 2 configured: 90 days, 8% APR");

  // Pool 3: 365 days, 5% APR
  await lendingPool.configurePool(
    3,
    "1-Year Pool",
    500,
    5000,
    3,
    365 * 24 * 60 * 60, // 1 year
    5,
    true
  );
  console.log("✅ Pool 3 configured: 365 days, 5% APR");

  console.log("\n🎉 Deployment complete!");
  console.log(`Contract address: ${address}`);
  console.log(`Admin: ${ADMIN_ADDRESS}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
