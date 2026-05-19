# Sleepless AI Contracts

Core smart contracts powering the Sleepless AI ecosystem, built on **BNB Smart Chain (BSC)** and compatible with EVM networks.

## Technology Stack

- **Blockchain**: BNB Smart Chain + opBNB
- **Smart Contracts**: Solidity ^0.8.x
- **Token Standards**: ERC20, ERC20Votes, ERC721A
- **Development**: Hardhat, OpenZeppelin, Chainlink VRF

## Supported Networks

- **BNB Smart Chain Mainnet** (Chain ID: 56)
- **opBNB Mainnet** (Chain ID: 204)

## Contract Addresses

### BNB Smart Chain

| Address |
|---|
| `0x06174c6c7c0363e33a17395a96ceff3674edb785` |
| `0x1a3a243915a0200697ba14554e96af3dd4e07867` |
| `0xcac410cd44717311f63aaf6081cb07244f10844f` |
| `0xdd009d957925400e028dcc53c4f2a84ac4fc2ba6` |
| `0xf382c2cb41f1628fda545d09696e911e85c02e25` |

### opBNB

| Address |
|---|
| `0x640eF170d28645B50A04abe1913872587CF8dCbB` |

## Features

- **AIToken.sol**
  - ERC20 ecosystem token
  - Governance voting support
  - Burnable supply

- **HERGT.sol**
  - ERC721A Genesis NFT contract
  - Limited collection design
  - Gas-optimized minting

- **HimVotes.sol**
  - HIM community voting system
  - Referral-based participation logic

- **HimCheckin.sol**
  - Activity participation and check-in system
  - Credit and voting integration

- **CheckIn.sol**
  - Event participation contract
  - Chainlink VRF reward logic
  - Signature verification

- **MerkleAirdrop.sol**
  - Merkle-based token distribution

- **SleepAiAirdrop.sol**
  - Batch ecosystem airdrop distribution

- **ExchangeHimCoin.sol**
  - BNB-to-HIM Coin exchange mechanism

## Ecosystem

Sleepless AI combines:

- AI companions
- Community participation
- Web3 ownership
- Event-driven interaction systems
- HIM & HER ecosystem infrastructure

## License

MIT
