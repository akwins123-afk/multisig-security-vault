🛡️ AegisGuard // MultiSig Security Vault
A decentralized treasury vault built with Solidity (0.8.24) that eliminates single points of failure using 2-of-3 multi-signature consensus and blocks recursive exploits before they happen.

🔗 Live Dashboard: https://akwins123-afk.github.io/multisig-security-vault/

✨ Key Features
2-of-3 Quorum Consensus: Funds cannot move without approval from at least 2 authorized signers.

Reentrancy Protection: Hardened with the Checks-Effects-Interactions (CEI) pattern and a custom non-reentrant mutex lock.

Tested Against Real Exploits: Includes an adversarial contract (ReentrancyAttacker.sol) verifying that recursive attacks revert immediately.

Circuit Breaker: Emergency killswitch that allows signers to pause outgoing transfers if suspicious activity is detected.

Cyberpunk Web3 Dashboard: An interactive browser terminal to submit proposals, sign transactions, and simulate reentrancy attacks in real time.

📂 Project Structure
contracts/MultiSigVault.sol — Core governance vault with mutex protection.

contracts/ReentrancyAttacker.sol — Exploit contract for adversarial verification.

index.html — Live Web3 security dashboard deployed via GitHub Pages.

🚀 Quick Start
Test the UI: Open index.html in any browser or visit the live GitHub Pages link above.

Deploy via Remix: Open Remix IDE, import the contracts, and deploy MultiSigVault.sol with 3 test accounts and a threshold of 2.
