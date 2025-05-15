import { plonk, groth16 } from "snarkjs";

describe("GenerateProof", function () {
  it("should generate proof", async function () {
    console.time("generate proof");
    let { proof, publicSignals } = await groth16.fullProve(
      {
        inPublicAmount: "1000",
        outPublicAmount: "0",
        inputAmounts: ["0", "0"],
        inputSecrets: ["0", "0"],
        outputAmounts: ["1000", "0"],
        outputSecrets: ["1", "0"],
      },
      "keys/transfer2_js/transfer2.wasm",
      "keys/circuit_0003.zkey",
    );
    console.timeEnd("generate proof");
  });
});
