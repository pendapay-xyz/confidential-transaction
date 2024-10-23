# Confidential Transaction on Ethereum
Using zk-SNARKs to implement confidential transaction. Shield amount transferring in transaction.

# Docs
1. [DESIGN](docs/DESIGN.md)

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
