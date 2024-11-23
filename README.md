# Blockchain Lottery Smart Contract 🎰

This repository contains a decentralized lottery application built on the Ethereum blockchain. The contract leverages Chainlink VRF for secure random number generation and Chainlink Keepers for automation.

## Table of Contents

- [Blockchain Lottery Smart Contract 🎰](#blockchain-lottery-smart-contract-)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Technologies Used](#technologies-used)
  - [Prerequisites](#prerequisites)
  - [Setup Instructions](#setup-instructions)

---

## Overview

The **Blockchain Lottery Smart Contract** is a decentralized application that allows users to participate in a transparent lottery. Winners are selected randomly using Chainlink VRF, ensuring a tamper-proof and fair process. The contract is automated using Chainlink Keepers, eliminating the need for manual intervention.

---

## Features

- **Decentralized Lottery**: No central authority is required.
- **Fair Randomness**: Powered by Chainlink VRF for verifiable randomness.
- **Automation**: Utilizes Chainlink Keepers to manage state transitions and ensure smooth operation.
- **Security**: Implements robust checks to prevent unauthorized operations.

---

## Technologies Used

- **Solidity**: Programming language for smart contracts.
- **Hardhat**: Development environment for Ethereum.
- **Chainlink VRF**: Verifiable Random Function for randomness.
- **Chainlink Keepers**: Automation of contract functions.
- **Ethers.js**: Interfacing with Ethereum.
- **Alchemy**: Ethereum node provider.

---

## Prerequisites

- **Node.js** and **npm**
- **Hardhat** installed globally
- **Metamask** wallet for deployment
- API keys for **Chainlink VRF** and **Alchemy**

---

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/blockchain-lottery.git
   cd blockchain-lottery

