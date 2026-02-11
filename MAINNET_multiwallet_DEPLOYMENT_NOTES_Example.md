# 🚀 Weritas Mainnet Deployment: 5-Step Guide

### 1. Multi-Sig Setup
Create a **Gnosis Safe** (or similar) on BSC Mainnet. This will be your `Admin`.

### 2. Environment Config
Populate your `.env` with the two separate addresses:
- `MULTI_SIG_ADMIN`: The address of your Safe Multi-sig.
- `OPERATOR_WALLET`: The address of your backend hot-wallet.

### 3. Deploy & Transfer
Run the governance script:
```bash
npx hardhat run scripts/deploy-governance.ts --network bscMainnet
```
*This deploys contracts and automatically "hands over the keys" to the Multi-sig.*

### 4. Verify Identity
Check BscScan for each contract to ensure you (the deployer) no longer have authority. The `DEFAULT_ADMIN_ROLE` must be the Multi-sig.

### 5. Secure Operator Token
Move the `OPERATOR_PRIVATE_KEY` to your production environment (e.g., AWS Secrets Manager, Vercel Env, or GitHub Secrets).

---

## 🎭 Role Definitions

- **The Admin (Multi-sig)**: 
  - *Permissions*: "Can change roles, grant/revoke access, upgrade logic, and modify protocol-level settings."
  - *Security*: Safe. Requires multiple people to hack.

- **The Operator (Hot Wallet)**: 
  - *Permissions*: "Can mint identities (WID), update reputation (PULSE), and perform daily automated tasks."
  - *Security*: Hot. Used by the backend. Can be revoked instantly by the Admin if compromised.

---

### 💡 Pro-Tip: Hardware vs. Multi-sig
- **Hardware Wallet (Ledger/Trezor)**: A physical device for ONE person. Great for personal security, but still a "Single Point of Failure."
- **Multi-sig (Gnosis Safe)**: A smart contract for a TEAM. Requires $M$-of-$N$ people to agree. **Industry Standard for Protocols.**
- **The Combo**: Use a Multi-sig where every "signer" is a Hardware Wallet. This is how the most secure protocols in the world are managed.
