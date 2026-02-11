# TokenDistributor Setup Guide

## Overview
The TokenDistributor contract manages token vesting schedules across multiple categories (Team, Investors, Community, etc.) with configurable cliff periods and linear vesting.

## Prerequisites
- Deployed token contract (ERC20)
- Admin wallet with gas funds
- **Multi-sig wallet for mainnet** (Gnosis Safe recommended)

## Deployment Steps

### 1. Configure Environment
```bash
# .env
TOKEN_ADDRESS=0x...        # Your deployed token address
ADMIN_ADDRESS=0x...        # Your admin wallet (use multi-sig for mainnet!)
PRIVATE_KEY=your_private_key
```

### 2. Deploy Contract
```bash
npx hardhat run scripts/deploy-token-distributor.ts --network bsc_mainnet
```

### 3. Mint Total Supply to Distributor
```bash
# Transfer all tokens to the TokenDistributor contract
# Example: 21 Billion tokens
await token.mint(distributorAddress, ethers.parseEther("21000000000"));
```

### 4. Renounce Minter Role (Optional but Recommended)
```solidity
// If your token has a minter role, renounce it to make supply immutable
await token.renounceRole(MINTER_ROLE, deployerAddress);
```

## How It Works

### Vesting Categories
The contract supports 5 default categories (customize as needed):
- **COMMUNITY** (0): Public distribution, airdrops
- **ECOSYSTEM** (1): Partnerships, grants
- **STRATEGIC** (2): Strategic investors
- **COUNCIL** (3): Governance council
- **TEAM** (4): Team and advisors

### Vesting Formula
```
Linear Vesting After Cliff:
- Before cliff: 0 tokens claimable
- After cliff: (totalAmount * timeElapsed) / vestDuration
- After full vesting: All remaining tokens claimable
```

### Example Schedules

| Category | Allocation | Cliff | Vesting | Example |
|----------|-----------|-------|---------|---------|
| COMMUNITY | 30% | 0 months | 24 months | Immediate start, 2-year release |
| ECOSYSTEM | 25% | 6 months | 36 months | 6-month wait, then 3-year release |
| STRATEGIC | 20% | 12 months | 24 months | 1-year wait, then 2-year release |
| COUNCIL | 15% | 12 months | 48 months | 1-year wait, then 4-year release |
| TEAM | 10% | 12 months | 48 months | 1-year wait, then 4-year release |

## Claiming Tokens

### As a Beneficiary
```javascript
// Anyone can call claim, but tokens go to the beneficiary
await distributor.claim(0); // Claim COMMUNITY tokens
```

### Check Claimable Amount
```javascript
const claimable = await distributor.calculateClaimable(0); // Category 0
console.log(`Claimable: ${ethers.formatEther(claimable)} tokens`);
```

### Get Full Vesting Info
```javascript
const info = await distributor.getVestingInfo(0);
console.log({
  totalAmount: ethers.formatEther(info.totalAmount),
  amountClaimed: ethers.formatEther(info.amountClaimed),
  claimable: ethers.formatEther(info.claimable),
  beneficiary: info.beneficiary
});
```

## Customization

### Add Custom Category
Modify the enum in the contract:
```solidity
enum Category { COMMUNITY, ECOSYSTEM, STRATEGIC, COUNCIL, TEAM, ADVISORS }
```

Then setup in deployment script:
```javascript
await distributor.setupCategory(
    5, // ADVISORS
    advisorMultiSigAddress,
    ethers.parseEther("1000000000"), // 1B tokens
    startTime,
    6 * MONTH,  // 6-month cliff
    2 * YEAR    // 2-year vesting
);
```

### Update Beneficiary (Emergency)
```javascript
// Only owner can update (use multi-sig for mainnet!)
await distributor.updateBeneficiary(0, newAddress);
```

## Multi-Sig Integration

### Recommended Setup
1. **Deploy with EOA** (externally owned account)
2. **Transfer ownership to multi-sig** after setup
3. **All beneficiaries should be multi-sig wallets** on mainnet

```javascript
// Transfer ownership to Gnosis Safe
await distributor.transferOwnership(gnosisSafeAddress);
```

See [MULTISIG_GUIDE.md](MULTISIG_GUIDE.md) for detailed multi-sig setup.

## Security Best Practices

### ✅ DO
- Use multi-sig for all beneficiary addresses on mainnet
- Test vesting schedules on testnet first
- Verify contract on block explorer
- Document all vesting schedules publicly
- Set up monitoring for claim events

### ❌ DON'T
- Use EOA (single wallet) as beneficiary on mainnet
- Change beneficiaries frequently
- Deploy without testing cliff/vesting calculations
- Forget to transfer tokens to the distributor contract

## Testing Vesting

### Fast-Forward Time (Hardhat Testnet)
```javascript
// Deploy and setup
const distributor = await TokenDistributor.deploy(token.address, owner.address);
await distributor.setupCategory(0, beneficiary, amount, startTime, 365 days, 730 days);

// Fast-forward past cliff (1 year)
await ethers.provider.send("evm_increaseTime", [366 * 24 * 60 * 60]);
await ethers.provider.send("evm_mine");

// Check claimable
const claimable = await distributor.calculateClaimable(0);
console.log(claimable); // Should be > 0 now

// Claim
await distributor.claim(0);
```

## Common Issues

### "Nothing to claim yet"
- Check if cliff period has passed
- Verify current timestamp vs. startTime + cliffDuration

### "Transfer failed"
- Ensure distributor contract has enough tokens
- Check token balance: `token.balanceOf(distributorAddress)`

### "Category already setup"
- Each category can only be initialized once
- Use `updateBeneficiary()` to change recipient

## Resources
- [Multi-Sig Setup Guide](MULTISIG_GUIDE.md)
- [Tokenomics Distribution Example](../TOKENOMICS_DISTRIBUTION_EXAMPLE.md)
- [OpenZeppelin Vesting Contracts](https://docs.openzeppelin.com/contracts/4.x/api/finance#VestingWallet)
