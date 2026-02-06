import { ethers, run, network } from "hardhat";
import * as fs from "fs";
import * as path from "path";

/**
 * @dev Main deployment logic for the framework.
 * This script is project-agnostic and reads from a central config.
 */
async function main() {
  // 1. Locate and load project configuration
  const configPath = path.join(__dirname, "../templates/launch-config.sample.json");
  if (!fs.existsSync(configPath)) {
    console.error("❌ Configuration file found at:", configPath);
    process.exit(1);
  }
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

  const { name, symbol, initialOwner } = config.token;

  console.log(`🚀 Starting deployment of ${name} (${symbol}) on ${network.name}...`);

  // 2. Deployment of the MasterToken instance
  const TokenFactory = await ethers.getContractFactory("MasterToken");
  const token = await TokenFactory.deploy(
    name, symbol, initialOwner || (await ethers.getSigners())[0].address
  );

  await token.waitForDeployment();
  const address = await token.getAddress();

  console.log(`✅ Token deployed at: ${address}`);

  // 3. Automated Source Code Verification (skip on local chains)
  if (network.name !== "hardhat" && network.name !== "localhost") {
    console.log("🔍 Starting contract verification...");
    try {
      await run("verify:verify", {
        address: address,
        constructorArguments: [name, symbol, initialOwner],
      });
      console.log("✨ Contract verified successfully!");
    } catch (error: any) {
      console.error("⚠️ Verification failed:", error.message);
    }
  }

  // 4. Record deployment artifacts for Frontend integration
  const deploymentData = {
    network: network.name,
    address: address,
    time: new Date().toISOString()
  };
  fs.writeFileSync(
    `deployment-${network.name}.json`,
    JSON.stringify(deploymentData, null, 2)
  );

  console.log("🎉 Process complete. Check deployment summary in root.");
}

// Global error handler
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
