import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { Hex, zeroAddress } from "viem";
import hre from "hardhat";
import { plonk } from "snarkjs";

describe("Magicpay", function () {
  async function deployMagicPayFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const verifier2 = await hre.viem.deployContract("PlonkVerifier2", [])
    const magicPay = await hre.viem.deployContract("MagicPay", [[verifier2.address], 0, zeroAddress])

    return {
      owner,
      otherAccount,
      magicPay,
    };
  }

  describe("Native token", function () {
    it("should transfer", async function () {
      const { owner, magicPay } = await loadFixture(deployMagicPayFixture);

      let { proof, publicSignals } = await plonk.fullProve(
        {
          inPublicAmount: "1000",
          outPublicAmount: "0",
          inputAmounts: ["0", "0"],
          inputSecrets: ["0", "0"],
          outputAmounts: ["1000", "0"],
          outputSecrets: ["1", "0"],
        },
        "keyProve/transfer2.wasm",
        "keyProve/circuit_final2.zkey",
      );

      const proofCalldata = await plonk.exportSolidityCallData(
        proof,
        publicSignals,
      );
      const matches = proofCalldata.match(/\[.*?\]/g);

      if (matches && matches.length === 2) {
        // Parse each matched section as JSON to get them as arrays
        proof = JSON.parse(matches[0]);
        publicSignals = JSON.parse(matches[1]);
      }

      const inputs = [publicSignals[0], publicSignals[1]] as readonly Hex[];
      const outputs = [
        {
          owner: owner.account.address,
          encryptedAmount: publicSignals[2] as Hex,
          message: "0x"
        },
        {
          owner: owner.account.address,
          encryptedAmount: publicSignals[3] as Hex,
          message: "0x"
        },
      ] as any;

      await magicPay.write.magicPay([zeroAddress, inputs, outputs, 1000n, 0n, zeroAddress, proof as any], {
        value: 1000n,
      });

      const transaction = await magicPay.read.getTransaction([outputs[0].encryptedAmount])
      console.log("New Transaction", transaction);
    });
  });
});
