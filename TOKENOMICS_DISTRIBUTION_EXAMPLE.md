# Weritas (WRTH) Tokenomics & Distribution

Weritas (WRTH) is designed for long-term ecosystem sustainability with a **fixed total supply** of 21,000,000,000 (21 Billion) tokens.

## 📊 Token Allocation

| Category | Allocation | Amount (WRTH) | Purpose |
| :--- | :--- | :--- | :--- |
| **Community Participation** | **30%** | 6,300,000,000 | Airdrops, Signup Bonuses, Presale refills |
| **Ecosystem Development** | **25%** | 5,250,000,000 | Marketing, Listings, Integrations |
| **Strategic Partners** | **20%** | 4,200,000,000 | Advisors, Infrastructure, Backers |
| **Council Reserves** | **15%** | 3,150,000,000 | Protocol Safety & Future Governance |
| **Team & Advisors** | **10%** | 2,100,000,000 | Core Development & Salaries |

---

## ⏳ Vesting & Release Schedule

All tokens are managed by the **TokenDistributor** smart contract to ensure transparency and automated release.

| Category | Cliff Period | Release Duration | Release Type |
| :--- | :--- | :--- | :--- |
| **Community** | 0 Months | 24 Months | Monthly Linear |
| **Ecosystem** | 6 Months | 36 Months | Monthly Linear |
| **Strategic** | 12 Months | 24 Months | Monthly Linear |
| **Council** | 12 Months | 48 Months | Monthly Linear |
| **Team/Advisors** | 12 Months | 48 Months | Monthly Linear |

---

## 🛡️ Security Mechanisms

1.  **Fixed Supply**: The `mint` function will be renounced once the 21 Billion tokens are issued to the Distributor contract.
2.  **Code-Enforced Cliff**: No tokens from the Team or Council buckets can be physically moved out of the contract until their respective 12-month cliff periods have passed.
3.  **Audit-Ready**: The distribution logic is open-source and verifiable on the blockchain (BSC/Mainnet).

---

## ⚙️ Management
- **Automated**: The **Weritas Backend** uses the Community bucket to automatically fund verified identity rewards.
- **Manual Control**: The Admin Council uses Multi-Sig wallets to claim and utilize the Ecosystem and Strategic buckets as needed.
