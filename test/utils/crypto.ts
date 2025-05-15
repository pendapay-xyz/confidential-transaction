import crypto, { CipherGCM, CipherGCMTypes, DecipherGCM } from "crypto";
import { plonk } from "snarkjs";
// TODO: wait for the next release of snarkjs to fix this
import * as snarkjs from "snarkjs";
import { base64, utf8 } from "@scure/base";
import nacl from "tweetnacl";

export type Password = string | Buffer | NodeJS.TypedArray | DataView;

export type EthEncryptedData = {
  nonce: string;
  ephemPublicKey: string;
  ciphertext: string;
};

export class CryptoEngine {
  getAlgorithm(): CipherGCMTypes {
    return "aes-256-gcm";
  }
  deriveKeyFromPassword(
    password: Password,
    salt: Buffer,
    iterations: number,
  ): Buffer {
    return crypto.pbkdf2Sync(password, salt, iterations, 32, "sha512");
  }

  getEncryptedPrefix(): string {
    return "enc::";
  }

  encryptAesGcm(
    plainText: string | object,
    password: Password,
  ): string | undefined {
    try {
      if (typeof plainText === "object") {
        plainText = JSON.stringify(plainText);
      } else {
        plainText = String(plainText);
      }

      const algorithm: CipherGCMTypes = this.getAlgorithm();

      // Generate random salt -> 64 bytes
      const salt = crypto.randomBytes(64);

      // Generate random initialization vector -> 16 bytes
      const iv = crypto.randomBytes(16);

      // Generate random count of iterations between 10.000 - 99.999 -> 5 bytes
      const iterations =
        Math.floor(Math.random() * (99999 - 10000 + 1)) + 10000;

      // Derive encryption key
      const encryptionKey = this.deriveKeyFromPassword(
        password,
        salt,
        Math.floor(iterations * 0.47 + 1337),
      );

      // Create cipher
      // @ts-ignore: TS expects the wrong createCipher return type here
      const cipher: CipherGCM = crypto.createCipheriv(
        algorithm,
        encryptionKey,
        iv,
      );

      // Update the cipher with data to be encrypted and close cipher
      const encryptedData = Buffer.concat([
        cipher.update(plainText, "utf8"),
        cipher.final(),
      ]);

      // Get authTag from cipher for decryption // 16 bytes
      const authTag = cipher.getAuthTag();

      // Join all data into single string, include requirements for decryption
      const output = Buffer.concat([
        salt,
        iv,
        authTag,
        Buffer.from(iterations.toString()),
        encryptedData,
      ]).toString("hex");

      return this.getEncryptedPrefix() + output;
    } catch (error) {
      console.error("Encryption failed!");
      console.error(error);
      return void 0;
    }
  }

  decryptAesGcm(cipherText: string, password: Password): string | undefined {
    try {
      const algorithm: CipherGCMTypes = this.getAlgorithm();

      const cipherTextParts = cipherText.split(this.getEncryptedPrefix());

      // If it's not encrypted by this, reject with undefined
      if (cipherTextParts.length !== 2) {
        console.error(
          "Could not determine the beginning of the cipherText. Maybe not encrypted by this method.",
        );
        return void 0;
      } else {
        cipherText = cipherTextParts[1] || "";
      }

      const inputData: Buffer = Buffer.from(cipherText, "hex");

      // Split cipherText into partials
      const salt: Buffer = inputData.slice(0, 64);
      const iv: Buffer = inputData.slice(64, 80);
      const authTag: Buffer = inputData.slice(80, 96);
      const iterations: number = parseInt(
        inputData.slice(96, 101).toString("utf-8"),
        10,
      );
      const encryptedData: Buffer = inputData.slice(101);

      // Derive key
      const decryptionKey = this.deriveKeyFromPassword(
        password,
        salt,
        Math.floor(iterations * 0.47 + 1337),
      );

      // Create decipher
      // @ts-ignore: TS expects the wrong createDecipher return type here
      const decipher: DecipherGCM = crypto.createDecipheriv(
        algorithm,
        decryptionKey,
        iv,
      );
      decipher.setAuthTag(authTag);

      // Decrypt data
      const decrypted = Buffer.concat([
        decipher.update(encryptedData),
        decipher.final(),
      ]).toString("utf-8");

      try {
        return JSON.parse(decrypted);
      } catch (error) {
        return decrypted;
      }
    } catch (error) {
      console.error("Decryption failed!");
      console.error(error);
      return void 0;
    }
  }

  encryptSymmetric = (publicKey: string, data: string): EthEncryptedData => {
    // generate ephemeral keypair
    const ephemeralKeyPair = nacl.box.keyPair();

    // assemble encryption parameters - from string to UInt8
    let pubKeyUInt8Array: Uint8Array;
    try {
      pubKeyUInt8Array = base64.decode(publicKey);
    } catch (err) {
      throw new Error("Bad public key");
    }

    const msgParamsUInt8Array = utf8.decode(data);
    const nonce = nacl.randomBytes(nacl.box.nonceLength);

    // encrypt
    const encryptedMessage = nacl.box(
      msgParamsUInt8Array,
      nonce,
      pubKeyUInt8Array,
      ephemeralKeyPair.secretKey,
    );

    // handle encrypted data
    const output = {
      nonce: base64.encode(nonce),
      ephemPublicKey: base64.encode(ephemeralKeyPair.publicKey),
      ciphertext: base64.encode(encryptedMessage),
    };
    // return encrypted msg data
    return output;
  };

  decryptSymmetric = (
    encryptedData: EthEncryptedData,
    privateKey: string,
  ): string => {
    const receiverPrivateKeyUint8Array = Buffer.from(privateKey, "hex");
    const receiverEncryptionPrivateKey = nacl.box.keyPair.fromSecretKey(
      receiverPrivateKeyUint8Array,
    ).secretKey;

    // assemble decryption parameters
    const nonce = base64.decode(encryptedData.nonce);
    const ciphertext = base64.decode(encryptedData.ciphertext);
    const ephemPublicKey = base64.decode(encryptedData.ephemPublicKey);

    // decrypt
    const decryptedMessage = nacl.box.open(
      ciphertext,
      nonce,
      ephemPublicKey,
      receiverEncryptionPrivateKey,
    );

    // return decrypted msg data
    try {
      if (!decryptedMessage) {
        throw new Error();
      }
      const output = utf8.encode(decryptedMessage);
      // TODO: This is probably extraneous but was kept to minimize changes during refactor
      if (!output) {
        throw new Error();
      }
      return output;
    } catch (err) {
      throw new Error(`Decryption failed. ${err}`);
    }
  };

  getEncryptionPublicKey = (privateKey: string): string => {
    const privateKeyUint8Array = Buffer.from(privateKey, "hex");
    const encryptionPublicKey =
      nacl.box.keyPair.fromSecretKey(privateKeyUint8Array).publicKey;
    return base64.encode(encryptionPublicKey);
  };

  calucateZkProof = async (proveParameters: any): Promise<[any, any]> => {
    let curve = await (snarkjs as any).curves.getCurveFromName("bn128");
    let { proof, publicSignals } = await plonk.fullProve(
      proveParameters,
      "circuits/transfer2.wasm",
      "circuits/circuit_final.zkey",
    );

    const proofCalldata = await plonk.exportSolidityCallData(
      proof,
      publicSignals,
    );

    const matches = proofCalldata.match(/\[.*?\]/g);

    if (matches && matches.length === 2) {
      // Parse each matched section as JSON to get them as arrays
      proof = JSON.parse(matches[0]);
      publicSignals = JSON.parse(matches[1] as string);
    }

    await curve.terminate();
    return [proof, publicSignals];
  };
}