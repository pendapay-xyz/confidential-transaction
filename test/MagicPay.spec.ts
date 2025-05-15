import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { Address, bytesToString, hashMessage, Hex, hexToString, stringToBytes, stringToHex, zeroAddress, zeroHash } from "viem";
import { privateKeyToAccount, generatePrivateKey } from "viem/accounts";
import hre from "hardhat";
import { plonk, groth16 } from "snarkjs";
import { CryptoEngine } from "./utils/crypto";

describe("Magicpay", function () {
  async function deployMagicPayFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const verifier2 = await hre.viem.deployContract("Groth16Verifier2", []);
    const magicPay = await hre.viem.deployContract("MagicPay", [
      verifier2.address,
      zeroAddress,
      0,
      zeroAddress,
    ]);

    return {
      owner,
      otherAccount,
      magicPay,
    };
  }

  const deposit = async (amount: bigint, receiver: Address) => {
    let { proof, publicSignals } = await groth16.fullProve(
      {
        inPublicAmount: amount.toString(),
        outPublicAmount: "0",
        inputAmounts: ["0", "0"],
        inputSecrets: ["0", "0"],
        outputAmounts: [amount.toString(), "0"],
        outputSecrets: ["1", "0"],
      },
      "keys/transfer2_js/transfer2.wasm",
      "keys/circuit_final.zkey"
    );

    const proofCalldata = await groth16.exportSolidityCallData(
      proof,
      publicSignals
    );

    const jsonData = `[${proofCalldata}]`;
    let pA, pB, pC;

    [pA, pB, pC, publicSignals] = JSON.parse(jsonData);
    console.log("Proof", pA, pB, pC);

    console.log("Public signals", publicSignals);

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

    console.log("Inputs", inputs);
    console.log("Outputs", outputs);

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
      }
    );

    console.log("Transaction", tx);
  };

  describe("Native token", function () {
    it("encryption", async function () {
      const account = privateKeyToAccount(generatePrivateKey())
      const signature = await account.signMessage({
        message: "Hello world",
      });
      const encryptionPrivateKey = hashMessage(signature).split("0x")[1];
      const cryptoEngine = new CryptoEngine();
      const encryptionPublicKey = cryptoEngine.getEncryptionPublicKey(encryptionPrivateKey)

      const data = cryptoEngine.encryptSymmetric(encryptionPublicKey, "Hello world");
      
      console.log("Signature", signature);
      console.log("Encryption private key", encryptionPrivateKey);
      console.log("Encryption public key", encryptionPublicKey);
      console.log("Encryption public key", stringToHex(encryptionPublicKey));
      console.log("Decrypted public key", hexToString(stringToHex(encryptionPublicKey)));
      console.log("Encrypted data", data);
      const decryptedData = cryptoEngine.decryptSymmetric(data, encryptionPrivateKey);

      console.log("Decrypted data", decryptedData);
    })
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
        "keys/transfer2_js/transfer2.wasm",
        "keys/circuit_final.zkey"
      );

      const proofCalldata = await groth16.exportSolidityCallData(
        proof,
        publicSignals
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
        }
      );

      const transactions = await magicPay.read.getTransactions([
        owner.account.address,
        zeroAddress, // native token
        zeroHash, // from head,
        10,
      ]);
    });
  });
});
