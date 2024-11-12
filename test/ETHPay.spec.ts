import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { Hex } from "viem";
import hre from "hardhat";
import { plonk } from "snarkjs";

describe("ETHPay", function () {
  async function deployETHPayFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const verifier2 = await hre.viem.deployContract("PlonkVerifier", [])
    const ethPay = await hre.viem.deployContract("ETHPay", [verifier2.address]);

    return {
      owner,
      otherAccount,
      ethPay,
    };
  }

  describe("Deployment", function () {
    it("should transfer", async function () {
      const { owner, ethPay } = await loadFixture(deployETHPayFixture);

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
          message: "0x",
        },
        {
          owner: owner.account.address,
          encryptedAmount: publicSignals[3] as Hex,
          message: "0x",
        },
      ] as any;

      await ethPay.write.pay2([inputs, outputs, 1000n, 0n, proof as any], {
        value: 1000n,
      });

      const txOwner = await ethPay.read.getOwner([outputs[0].encryptedAmount])
      console.log("New Transaction owner", txOwner)
    });
  });
});
