import { ethers } from "hardhat";

async function main() {
  console.log("Deploying TokenDistributor...");

  // Configuration
  const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "0x..."; // Your token address
  const ADMIN_ADDRESS = process.env.ADMIN_ADDRESS || (await ethers.getSigners())[0].address;

  // Deploy
  const TokenDistributor = await ethers.getContractFactory("TokenDistributor");
  const distributor = await TokenDistributor.deploy(TOKEN_ADDRESS, ADMIN_ADDRESS);
  await distributor.waitForDeployment();

  const address = await distributor.getAddress();
  console.log(`✅ TokenDistributor deployed to: ${address}`);

  // Example: Setup categories (customize for your project)
  console.log("\nSetting up vesting categories...");

  const startTime = Math.floor(Date.now() / 1000); // Now
  const MONTH = 30 * 24 * 60 * 60;
  const YEAR = 365 * 24 * 60 * 60;

  // Category 0: COMMUNITY - 30% - No cliff, 2-year vesting
  await distributor.setupCategory(
    0, // COMMUNITY
    "0x...", // Beneficiary address (use multi-sig for mainnet!)
    ethers.parseEther("6300000000"), // 6.3B tokens (30%)
    startTime,
    0, // No cliff
    2 * YEAR // 2-year vesting
  );
  console.log("✅ COMMUNITY: 30%, No cliff, 2-year vesting");

  // Category 1: ECOSYSTEM - 25% - 6-month cliff, 3-year vesting
  await distributor.setupCategory(
    1, // ECOSYSTEM
    "0x...",
    ethers.parseEther("5250000000"), // 5.25B tokens (25%)
    startTime,
    6 * MONTH,
    3 * YEAR
  );
  console.log("✅ ECOSYSTEM: 25%, 6-month cliff, 3-year vesting");

  // Category 2: STRATEGIC - 20% - 1-year cliff, 2-year vesting
  await distributor.setupCategory(
    2, // STRATEGIC
    "0x...",
    ethers.parseEther("4200000000"), // 4.2B tokens (20%)
    startTime,
    1 * YEAR,
    2 * YEAR
  );
  console.log("✅ STRATEGIC: 20%, 1-year cliff, 2-year vesting");

  // Category 3: COUNCIL - 15% - 1-year cliff, 4-year vesting
  await distributor.setupCategory(
    3, // COUNCIL
    "0x...",
    ethers.parseEther("3150000000"), // 3.15B tokens (15%)
    startTime,
    1 * YEAR,
    4 * YEAR
  );
  console.log("✅ COUNCIL: 15%, 1-year cliff, 4-year vesting");

  // Category 4: TEAM - 10% - 1-year cliff, 4-year vesting
  await distributor.setupCategory(
    4, // TEAM
    "0x...",
    ethers.parseEther("2100000000"), // 2.1B tokens (10%)
    startTime,
    1 * YEAR,
    4 * YEAR
  );
  console.log("✅ TEAM: 10%, 1-year cliff, 4-year vesting");

  console.log("\n🎉 Deployment complete!");
  console.log(`Contract address: ${address}`);
  console.log(`\n⚠️  IMPORTANT: Transfer 21B tokens to this contract address!`);
  console.log(`Then renounce minter role if applicable.`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
