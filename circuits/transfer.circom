pragma circom 2.0.0;
include "../node_modules/circomlib/circuits/poseidon.circom";

template Transfer(numIns, numOuts) {
    signal input inPublicAmount; // for deposit
    signal input outPublicAmount; // for withdraw

    signal input inputAmounts[numIns];
    signal input inputSecrets[numIns];
    signal output inputNullifiers[numIns];

    signal input outputAmounts[numOuts];
    signal input outputSecrets[numOuts];
    signal output outputNullifiers[numOuts];

    component inCommitmentHasher[numIns];
    var sumIns = 0;

    for (var tx = 0; tx < numIns; tx++) {
        inCommitmentHasher[tx] = Poseidon(2);
        inCommitmentHasher[tx].inputs[0] <== inputAmounts[tx];
        inCommitmentHasher[tx].inputs[1] <== inputSecrets[tx];

        inputNullifiers[tx] <== inCommitmentHasher[tx].out;

        sumIns += inputAmounts[tx];
    }

    component outCommitmentHasher[numOuts];
    var sumOuts = 0;

    for (var tx = 0; tx < numOuts; tx++) {
        outCommitmentHasher[tx] = Poseidon(2);
        outCommitmentHasher[tx].inputs[0] <== outputAmounts[tx];
        outCommitmentHasher[tx].inputs[1] <== outputSecrets[tx];

        outputNullifiers[tx] <== outCommitmentHasher[tx].out;

        sumOuts += outputAmounts[tx];
    }

    sumIns + inPublicAmount === outPublicAmount + sumOuts;
}
