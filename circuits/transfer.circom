pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template Transfer(numIns, numOuts) {
    signal input inputNullifier[numIns];
    signal input inputAmounts[numIns];
    signal input inputSecrets[numIns];

    signal input outputNullifier[numOuts];
    signal input outputAmounts[numOuts];
    signal input outputSecrets[numOuts];

    component inCommitmentHasher[numIns];
    var sumInts = 0;

    for (var tx = 0; tx < numIns; tx++) {
        inCommitmentHasher[tx] = Poseidon(2);

        inCommitmentHasher[tx].input[0] <== inputAmounts[tx];
        inCommitmentHasher[tx].input[1] <== inputSecrets[tx];
        inCommitmentHasher[tx].out === inputNullifier[tx];

        sumIns = sumIns + inputAmounts[tx];
    }
}

component main {public [inputNullifier, outputNullifier]} = Transfer(2, 2);