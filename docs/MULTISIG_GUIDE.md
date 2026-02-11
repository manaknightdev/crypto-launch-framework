# Multi-Sig Wallet Setup (Gnosis Safe)

## Why Multi-Sig for Mainnet?
- **Security**: Requires multiple approvals for critical actions
- **Decentralization**: No single point of failure
- **Trust**: Transparent governance for token holders

## Use Cases
1. **TokenDistributor Admin**: Control vesting schedules and allocations
2. **LendingPool Admin**: Manage pool configurations and withdrawals
3. **Treasury Management**: Secure large fund movements

## Setup Steps

### 1. Create Gnosis Safe Wallet

**Option A: Via Gnosis Safe App**
1. Visit [safe.global](https://safe.global)
2. Click "Create New Safe"
3. Select network (BSC Mainnet, Ethereum, etc.)
4. Add owner addresses (3-5 recommended)
5. Set threshold (e.g., 2-of-3, 3-of-5)
6. Deploy Safe (requires gas from one owner)

**Option B: Via Smart Contract**
```solidity
// Deploy GnosisSafeProxy with factory
// See: https://github.com/safe-global/safe-contracts
```

### 2. Configure Safe for TokenDistributor

```javascript
// After deploying TokenDistributor
const distributorAddress = "0x...";

// Transfer admin role to Safe
await tokenDistributor.grantRole(
    await tokenDistributor.DEFAULT_ADMIN_ROLE(),
    gnosisSafeAddress
);

// Renounce deployer's admin role
await tokenDistributor.renounceRole(
    await tokenDistributor.DEFAULT_ADMIN_ROLE(),
    deployerAddress
);
```

### 3. Configure Safe for LendingPool

```javascript
// Transfer admin role to Safe
await lendingPool.grantRole(
    await lendingPool.DEFAULT_ADMIN_ROLE(),
    gnosisSafeAddress
);

// Renounce deployer's admin role
await lendingPool.renounceRole(
    await lendingPool.DEFAULT_ADMIN_ROLE(),
    deployerAddress
);
```

## Multi-Sig Operations

### Example: Configure New Lending Pool
1. **Owner 1** creates transaction in Safe UI:
   ```
   To: LendingPool Contract
   Function: configurePool(...)
   Parameters: [poolId, name, requirement, ...]
   ```
2. **Owner 2** reviews and approves
3. **Owner 3** approves (if 3-of-5 threshold)
4. Transaction executes automatically

### Example: Withdraw from TokenDistributor
1. Create transaction: `withdraw(amount, recipient)`
2. Collect required signatures
3. Execute on-chain

## Recommended Configuration

| Use Case | Owners | Threshold | Example |
|----------|--------|-----------|---------|
| **Small Team** | 3 | 2-of-3 | Startup with 3 founders |
| **Medium Team** | 5 | 3-of-5 | Project with core team + advisors |
| **DAO Governance** | 7+ | 4-of-7 | Community-governed project |

## Security Best Practices
1. **Diversify owners**: Use different hardware wallets
2. **Geographic distribution**: Owners in different locations
3. **Backup keys**: Secure seed phrases in multiple locations
4. **Test on testnet first**: Practice multi-sig operations
5. **Document procedures**: Clear process for emergency actions

## Emergency Recovery
- Set up a time-lock for owner changes
- Consider a "guardian" role for critical recovery
- Document recovery procedures for all owners

## Resources
- [Gnosis Safe Documentation](https://docs.safe.global)
- [Safe Contracts GitHub](https://github.com/safe-global/safe-contracts)
- [Multi-Sig Best Practices](https://blog.openzeppelin.com/gnosis-safe-multisig-wallet-audit)
