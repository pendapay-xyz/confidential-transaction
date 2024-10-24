# Confidential Transaction on Ethereum
Maskpay implement an Ethereum zk-proofs based protocol for privacy preserving payments. This allow users to make payments without revealing the amount of the payment.

> **Note:** Only amount of the payment is hidden, the sender and receiver addresses are still visible on the blockchain preventing money laundering.

# How it works
Maskpay using zk-SNARKs to prove the validity of a transaction without revealing the amount of the transaction. The sender creates a proof that the transaction is valid and the amount is correct. The proof is then verified by the smart contract on the blockchain.

# Requirements
1. Circom
2. Snarkjs

# Circuits
1. How to compile circuits
```sh
circom circuits/transfer10.circom  -o build --r1cs --wasm
circom circuits/transfer2.circom  -o build --r1cs --wasm
```

2. Setup proving key and verifying key

3. Export verify contracts
```sh
snarkjs zkey export solidityverifier // TODO
```

## Use cases
1. Salary payment
2. Business transfer
3. Confidential
