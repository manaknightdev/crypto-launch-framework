import { ethers, network } from "hardhat";
import * as fs from "fs";
import * as path from "path";

async function main() {
  // 1. Get configuration
  const configPath = path.join(__dirname, "../launch-config.json");
  // Check if we are running from the framework or a copied project
  const localConfigPath = path.join(__dirname, "../launch-config.json");
  const templateConfigPath = path.join(__dirname, "../templates/launch-config.sample.json");
  
  let config;
  if (fs.existsSync(localConfigPath)) {
      config = JSON.parse(fs.readFileSync(localConfigPath, "utf8"));
  } else if (fs.existsSync(templateConfigPath)) {
       // Fallback for testing in framework
      config = JSON.parse(fs.readFileSync(templateConfigPath, "utf8"));
  } else {
      console.error("❌ No launch-config.json found.");
      process.exit(1);
  }

  // 2. Get deployed address
  // This expects the deployment script to have run and created this file
  const deployParamsPath = `deployment-${network.name}.json`;
  if (!fs.existsSync(deployParamsPath)) {
    console.error(`❌ No deployment file found for ${network.name}. Run deploy.ts first.`);
    process.exit(1);
  }
  const deployData = JSON.parse(fs.readFileSync(deployParamsPath, "utf8"));
  const contractAddress = deployData.address;

  const { name, symbol } = config.token;

  console.log(`🪙   interacting with ${name} (${symbol}) at ${contractAddress}`);

  // 3. Attach to Contract
  // We use "MasterToken" interface since your token inherits from it
  const MasterToken = await ethers.getContractFactory("MasterToken");
  const token = MasterToken.attach(contractAddress);

  // 4. Execute Mint
  // EDIT HERE: Address to receive tokens and amount
  const recipient = "0x80566bE113655A1405bE0023E37bf4F7f3301dFB"; 
  const amount = ethers.parseUnits("1000", 18); // Mint 1000 tokens

  console.log(`⏳ Minting ${ethers.formatUnits(amount, 18)} tokens to ${recipient}...`);

  try {
    // @ts-ignore
    const tx = await token.mint(recipient, amount);
    await tx.wait();
    console.log(`✅ Mint Successful! Tx Hash: ${tx.hash}`);
    
    // Check outcome
    // @ts-ignore
    const balance = await token.balanceOf(recipient);
    console.log(`💰 New Balance: ${ethers.formatUnits(balance, 18)} ${symbol}`);
  } catch (err: any) {
    console.error("❌ Mint failed:", err.message);
    if (err.message.includes("AccessControl")) {
      console.log("👉 Reason: Caller is not a minter.");
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
