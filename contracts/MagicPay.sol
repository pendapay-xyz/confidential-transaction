// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./interfaces/IPlonkVerifier.sol";

contract MagicPay {
    address private _verifier2;
    mapping (bytes32 => address) internal _transactions;

    struct Output {
        address owner;
        bytes32 encryptedAmount;
        bytes message;
    }

    function _pay2(bytes32[] calldata inputs, Output[] calldata outputs, uint256 inAmount, uint256 outAmount, uint256[24] calldata proof) internal {
        for (uint256 i = 0; i < inputs.length; i++) {
            require(_transactions[inputs[i]] == msg.sender, "Invalid transaction");
            delete _transactions[inputs[i]];
        }

        for (uint256 i = 0; i < outputs.length; i++) {
            require(_transactions[outputs[i].encryptedAmount] == address(0), "Existed transaction");
            _transactions[outputs[i].encryptedAmount] = outputs[i].owner;
        }

        require(IPlonkVerifier(_verifier2).verifyProof(proof, [inAmount, outAmount, uint256(inputs[0]), uint256(inputs[1]), uint256(outputs[0].encryptedAmount), uint256(outputs[1].encryptedAmount)]), "Invalid proof");
    }

}
