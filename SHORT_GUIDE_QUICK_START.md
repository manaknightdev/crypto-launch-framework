# ⚡ Quick Start
1. **Init**: `npx hardhat init` (Select TypeScript).
2. **Install**: `npm i -D hardhat@2.28.0 @openzeppelin/contracts dotenv @nomicfoundation/hardhat-toolbox`
3. **Setup**: Create `contracts/` folder. Put `MasterToken.sol` & your `MyToken.sol` there.
4. **Secrets**: Create `.env` with `PRIVATE_KEY=0x...` and `BSCSCAN_API_KEY=...`.
5. **Config**: Copy `hardhat.config.ts`, `scripts/deploy.ts`, and `scripts/mint.ts` to your project.
6. **Deploy**: `npx hardhat run scripts/deploy.ts --network bscTestnet`
7. **Mint**: `npx hardhat run scripts/mint.ts --network bscTestnet`
