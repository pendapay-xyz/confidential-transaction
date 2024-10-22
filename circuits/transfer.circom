pragma circom 2.0.0;
include "../node_modules/circomlib/circuits/poseidon.circom";

template Transfer(numIns, numOuts) {
    signal input inputNullifiers[numIns];
    signal input inputAmounts[numIns];
    signal input inputSecrets[numIns];

    signal input outputNullifiers[numOuts];
    signal input outputAmounts[numOuts];
    signal input outputSecrets[numOuts];

    signal input outPublicAmount; // for withdraw

    component inCommitmentHasher[numIns];
    var sumIns = 0;

    for (var tx = 0; tx < numIns; tx++) {
        inCommitmentHasher[tx] = Poseidon(2);
        inCommitmentHasher[tx].inputs[0] <== inputAmounts[tx];
        inCommitmentHasher[tx].inputs[1] <== inputSecrets[tx];

        inCommitmentHasher[tx].out === inputNullifiers[tx];

        sumIns += inputAmounts[tx];
    }

    component outCommitmentHasher[numOuts];
    var sumOuts = 0;

    for (var tx = 0; tx < numOuts; tx++) {
        outCommitmentHasher[tx] = Poseidon(2);
        outCommitmentHasher[tx].inputs[0] <== outputAmounts[tx];
        outCommitmentHasher[tx].inputs[1] <== outputSecrets[tx];

        outCommitmentHasher[tx].out === outputNullifiers[tx];

        sumOuts += outputAmounts[tx];
    }

    sumIns === outPublicAmount + sumOuts;
}
