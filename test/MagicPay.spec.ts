import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { Hex, zeroAddress } from "viem";
import hre from "hardhat";
import { plonk } from "snarkjs";

describe("Magicpay", function () {
  async function deployMagicPayFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const verifier2 = await hre.viem.deployContract("PlonkVerifier", [])
    const magicPay = await hre.viem.deployContract("MagicPay", [verifier2.address]);

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
        "transfer2.wasm",
        "circuit_final.zkey",
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
        },
        {
          owner: owner.account.address,
          encryptedAmount: publicSignals[3] as Hex,
        },
      ] as any;

      await magicPay.write.pay2([zeroAddress, inputs, outputs, 1000n, 0n, proof as any, "0x"], {
        value: 1000n,
      });

      const transaction = await magicPay.read.getTransaction([outputs[0].encryptedAmount])
      console.log("New Transaction", transaction);
    });
  });
});
