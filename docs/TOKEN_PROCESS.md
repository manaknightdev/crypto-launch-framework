# Technical Token Implementation Guide

This guide provides a step-by-step technical walkthrough for implementing a new token using this framework.

## Step 1: Smart Contract Implementation

### 1.1 Inheritance
Your token should inherit from the `MasterToken.sol` template. This provides the following out-of-the-box:
- **ERC20**: Standard token functionality.
- **ERC20Burnable**: Ability to destroy tokens.
- **ERC20Permit**: Support for EIP-2612 gasless approvals.
- **AccessControl**: Granular permission management.

### 1.2 The Mint Function
The `mint` function is protected by the `MINTER_ROLE`. This allows the project to authorize specific addresses (like a backend server or a presale contract) to create new tokens.

```solidity
function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
}
```

### 1.3 Customization
If your project requires unique logic (e.g., transaction taxes, automatic liquidity pool seeding), implement them by overriding the `_update` function in the standard ERC20 implementation.

---

## Step 2: Deployment Configuration

Decouple your deployment logic from your code by using the `launch-config.json`.

```json
{
  "token": {
    "name": "ProjectAlpha",
    "symbol": "ALPHA",
    "initialOwner": "0x..."
  },
  "networks": {
    "ethereum": { "verify": true },
    "bsc": { "verify": true }
  }
}
```

---

## Step 3: Deployment Execution

1.  Navigate to the `scripts/` directory.
2.  Run the deployment command:
    ```bash
    npx hardhat run scripts/deploy.ts --network <network_name>
    ```
3.  The script will:
    - Compile the contracts.
    - Deploy to the specified target.
    - Automatically verify the source code on the blockchain explorer.
    - Export the deployment address and ABI to a local JSON file.

---

