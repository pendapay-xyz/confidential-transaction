import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { Hex, zeroAddress } from "viem";
import hre from "hardhat";
import { plonk, groth16 } from "snarkjs";

describe("Magicpay", function () {
  async function deployMagicPayFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const verifier2 = await hre.viem.deployContract("Groth16Verifier", []);
    const magicPay = await hre.viem.deployContract("MagicPay", [
      [verifier2.address],
      0,
      zeroAddress,
    ]);

    return {
      owner,
      otherAccount,
      magicPay,
    };
  }

  describe("Native token", function () {
    it("should transfer", async function () {
      const { owner, magicPay } = await loadFixture(deployMagicPayFixture);

      let { proof, publicSignals } = await groth16.fullProve(
        {
          inPublicAmount: "1000",
          outPublicAmount: "0",
          inputAmounts: ["0", "0"],
          inputSecrets: ["0", "0"],
          outputAmounts: ["1000", "0"],
          outputSecrets: ["1", "0"],
        },
        "keyProve/transfer2.wasm",
        "build/circuit_0003.zkey",
      );

      const proofCalldata = await groth16.exportSolidityCallData(
        proof,
        publicSignals,
      );

      const jsonData = `[${proofCalldata}]`;
      let pA, pB, pC;

      [pA, pB, pC, publicSignals] = JSON.parse(jsonData);

      const inputs = [publicSignals[0], publicSignals[1]] as readonly Hex[];
      const outputs = [
        {
          owner: owner.account.address,
          encryptedAmount: publicSignals[2] as Hex,
          message: "0x",
        },
        {
          owner: owner.account.address,
          encryptedAmount: publicSignals[3] as Hex,
          message: "0x",
        },
      ] as any;

      const tx = await magicPay.write.magicPay(
        [
          zeroAddress,
          inputs,
          outputs,
          1000n,
          0n,
          zeroAddress,
          {
            pA,
            pB,
            pC,
          },
        ],
        {
          value: 1000n,
        },
      );

      console.log("Transaction", tx);

      const transaction = await magicPay.read.getTransaction([
        outputs[0].encryptedAmount,
      ]);
      console.log("New Transaction", transaction);
    });
  });
});
