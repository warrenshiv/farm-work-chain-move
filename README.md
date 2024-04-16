# Farm Work Chain

## Overview

The `farm_work_chain` module on the Sui blockchain platform is engineered to streamline the management of agricultural labor through a sophisticated decentralized network. This module empowers farmers with robust tools to create detailed work contracts, hire competent workers, manage disputes effectively, and release payments securely. 

## Table of Contents

1. [Installation and Deployment](#installation-and-deployment)
2. [Features](#features)
3. [Usage](#usage)
   - [Creating Work Contracts](#creating-work-contracts)
   - [Bidding and Work Submission](#bidding-and-work-submission)
   - [Dispute Resolution](#dispute-resolution)
   - [Payment Release and Cancellation](#payment-release-and-cancellation)
   - [Additional Functionality](#additional-functionality)
4. [Examples](#examples)
5. [References](#references)

### Prerequisites
1. Install dependencies by running the following commands:

   - `sudo apt update`
   
   - `sudo apt install curl git-all cmake gcc libssl-dev pkg-config libclang-dev libpq-dev build-essential -y`

2. Install Rust and Cargo

   - `curl https://sh.rustup.rs -sSf | sh`
   
   - source "$HOME/.cargo/env"

3. Install Sui Binaries
   
   - run the command `chmod u+x sui-binaries.sh` to make the file an executable
   
   execute the installation file by running

   - `./sui-binaries.sh "v1.21.0" "devnet" "ubuntu-x86_64"` for Debian/Ubuntu Linux users
   
   - `./sui-binaries.sh "v1.21.0" "devnet" "macos-x86_64"` for Mac OS users with Intel based CPUs
   
   - `./sui-binaries.sh "v1.21.0" "devnet" "macos-arm64"` for Silicon based Mac 

For detailed installation instructions, refer to the [Installation and Deployment](#installation-and-deployment) section in the provided documentation.

## Installation

1. Clone the repo
   ```sh
   git clone https://github.com/warrenshiv/farm-work-chain-move.git
   ```
2. Navigate to the working directory
   ```sh
   cd Farm_Work_Chain
   ```

## Build and Deploy the smart contract

1. Build
   
   - `sui move build`

2. Deploy/Publish
   - `sui client publish --gas-budget 1000000000`

## Structs

1. FarmWork
   
   ```
   {
      id: UID,
      farmer: address,
      description: vector<u8>,
      required_skills: vector<u8>,
      category: vector<u8>,
      price: u64,
      escrow: Balance<SUI>,
      dispute: bool,
      rating: Option<u64>,
      status: vector<u8>,
      worker: Option<address>,
      workSubmitted: bool,
      created_at: u64,
      deadline: u64,
   }
   ```

2. WorkRecord
   ```
   {
      id: UID,
      farmer: address,
      review: vector<u8>,
   }
   ```

## Errors
   
-  EInvalidBid: u64 = 1;
-  EInvalidWork: u64 = 2;
-  EDispute: u64 = 3;
-  EAlreadyResolved: u64 = 4;
-  ENotworker: u64 = 5;
-  EInvalidWithdrawal: u64 = 6;
-  EDeadlinePassed: u64 = 7;
-  EInsufficientEscrow: u64 = 8;

## Core Functionalities

### create_work 🌱

- **Parameters**:
  - description: `vector<u8>`
  - category: `vector<u8>`
  - required_skills: `vector<u8>`
  - price: `u64`
  - clock: `&Clock`
  - duration: `u64`
  - open: `vector<u8>`
  - ctx: `&mut TxContext`

- **Description**: Creates a new work contract with details about the work, skills required, payment terms, and timeline.

- **Errors**:
  - **EInvalidBid**: if a bid is already present or other issues related to bidding occur.

### hire_worker 👷

- **Parameters**:
  - work: `&mut FarmWork`
  - ctx: `&mut TxContext`

- **Description**: Assigns a worker to a specific `FarmWork` if no worker has been hired yet.

- **Errors**:
  - **EInvalidBid**: if there is already a worker assigned.

### submit_work 📤

- **Parameters**:
  - work: `&mut FarmWork`
  - clock: `&Clock`
  - ctx: `&mut TxContext`

- **Description**: Marks the work as submitted by the worker before the deadline.

- **Errors**:
  - **EDeadlinePassed**: if the submission is attempted after the deadline.
  - **EInvalidWork**: if the work does not meet specified requirements.

### resolve_dispute ⚖️

- **Parameters**:
  - work: `&mut FarmWork`
  - resolved: `bool`
  - ctx: `&mut TxContext`

- **Description**: Resolves a dispute between farmer and worker, potentially redistributing escrow funds based on the resolution.

- **Errors**:
  - **EDispute**: if there is no ongoing dispute.
  - **EAlreadyResolved**: if the dispute has already been resolved.
  - **EInvalidBid**: if no worker was ever hired.

### release_payment 💵

- **Parameters**:
  - work: `&mut FarmWork`
  - clock: `&Clock`
  - review: `vector<u8>`
  - ctx: `&mut TxContext`

- **Description**: Releases the escrow payment to the worker upon successful completion and review of the work.

- **Errors**:
  - **EInsufficientEscrow**: if the escrow balance is too low to cover the payment.
  - **EDeadlinePassed**: if the payment is attempted after the work is overdue.
  - **EInvalidWork**: if the work does not meet the completion criteria.

### add_funds 💰

- **Parameters**:
  - work: `&mut FarmWork`
  - amount: `Coin<SUI>`
  - ctx: `&mut TxContext`

- **Description**: Adds additional funds to the escrow for a `FarmWork` to ensure there are sufficient funds to cover the work payment.

- **Errors**:
  - **ENotworker**: if the action is performed by someone other than the farmer.

### cancel_work 🚫

- **Parameters**:
  - work: `&mut FarmWork`
  - ctx: `&mut TxContext`

- **Description**: Cancels the work contract, refunding the funds from escrow if applicable and resetting the work state.

- **Errors**:
  - **ENotworker**: if the cancellation is attempted by someone other than the farmer or hired worker.
  - **EInvalidWithdrawal**: if an invalid attempt is made to withdraw funds.

### update_work_details 📝

- **Parameters**:
  - work: `&mut FarmWork`
  - new_details: `vector<u8>` (Depending on the attribute being updated, e.g., description, price, deadline)
  - ctx: `&mut TxContext`

- **Description**: Updates specific details of the `FarmWork`, such as description, price, or deadline.

- **Errors**:
  - **ENotworker**: if the update is attempted by someone other than the farmer.
