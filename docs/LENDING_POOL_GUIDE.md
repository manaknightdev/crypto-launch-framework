# LendingPool Setup Guide

## Overview
The LendingPool contract enables reputation-based lending with configurable deadlines and interest rates per tier.

## Prerequisites
- Deployed stablecoin contract (USDT/USDC)
- Backend service with reputation scoring system
- Admin wallet with gas funds

## Deployment Steps

### 1. Configure Environment
```bash
# .env
STABLECOIN_ADDRESS=0x... # Your USDT/USDC address
ADMIN_ADDRESS=0x...      # Your admin wallet
PRIVATE_KEY=your_private_key
```

### 2. Deploy Contract
```bash
npx hardhat run scripts/deploy-lending-pool.ts --network bsc_testnet
```

### 3. Configure Pools
The deployment script automatically configures 3 example pools:
- **Pool 1**: 30 days, 10% APR, $500 loan
- **Pool 2**: 90 days, 8% APR, $1000 loan
- **Pool 3**: 365 days, 5% APR, $5000 loan

### 4. Fund the Pool
```bash
# Transfer USDT to the contract address
# Example: Transfer 10,000 USDT to cover initial loans
```

### 5. Authorize Backend Validator
```solidity
// Call from admin wallet
lendingPool.setValidator(backendWalletAddress, true);
```

## How It Works

### Borrowing Flow
1. **Backend validates** user's reputation score
2. **Backend calls** `createLoan(borrowerAddress, poolId, reputationScore)`
3. **Contract records** loan details on-chain (address, amount, timestamp)
4. **USDT transfers** from contract to borrower automatically

### Repayment Flow
1. **Borrower approves** contract to spend USDT
2. **Borrower calls** `repayLoan(loanId)`
3. **Contract calculates** interest based on time elapsed
4. **USDT transfers** from borrower back to contract
5. **Loan marked** as repaid on-chain

### Default Detection
- Contract automatically tracks if loan exceeds deadline
- Call `isDefaulted(loanId)` to check status
- Validators can call `liquidate(loanId)` to close defaulted loans

## Testing Default Logic

```javascript
// Example: Test 30-day deadline
// 1. Create loan from Pool 1 (30-day duration)
await lendingPool.createLoan(borrowerAddress, 1, 150);

// 2. Fast-forward time in testnet (Hardhat)
await ethers.provider.send("evm_increaseTime", [31 * 24 * 60 * 60]); // 31 days
await ethers.provider.send("evm_mine");

// 3. Check if defaulted
const isDefaulted = await lendingPool.isDefaulted(loanId);
console.log(isDefaulted); // true

// 4. Liquidate
await lendingPool.liquidate(loanId);
```

## Customization

### Add New Pool
```solidity
lendingPool.configurePool(
    4,                      // Pool ID
    "Custom Pool",          // Name
    1000,                   // Min reputation score
    10000,                  // $10,000 loan
    4,                      // Tier 4
    180 * 24 * 60 * 60,    // 180 days (6 months)
    12,                     // 12% APR
    true                    // Active
);
```

### Modify Interest Rate
```solidity
// Update existing pool's interest rate
lendingPool.configurePool(
    1,                      // Pool ID to update
    "30-Day Pool",
    100,
    500,
    1,
    30 * 24 * 60 * 60,
    15,                     // NEW: 15% APR (was 10%)
    true
);
```

## Security Notes
- Use multi-sig wallet for admin role on mainnet
- Validators should be secure backend wallets
- Monitor pool balance to ensure sufficient liquidity
- Implement reputation system off-chain for flexibility
