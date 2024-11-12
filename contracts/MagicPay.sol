// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./interfaces/IPlonkVerifier.sol";

contract MagicPay {
    address private _verifier2;
    mapping (bytes32 => address) internal _transactions;

    uint256 public ZERO_TX = 14744269619966411208579211824598458697587494354926760081771325075741142829156;

    struct Output {
        address owner;
        bytes32 encryptedAmount;
        bytes message;
    }

    function __MagicPay_init(address verifier2) internal {
        _verifier2 = verifier2;
    }

    function _pay2(bytes32[] calldata inputs, Output[] calldata outputs, uint256 inAmount, uint256 outAmount, uint256[24] calldata proof) internal {
        for (uint256 i = 0; i < inputs.length; i++) {
            if (inputs[i] == bytes32(ZERO_TX)) {
                // Skip zero tx
                continue;
            }
            require(_transactions[inputs[i]] == msg.sender, "Invalid transaction");
            delete _transactions[inputs[i]];
        }

        for (uint256 i = 0; i < outputs.length; i++) {
            if (outputs[i].encryptedAmount == bytes32(ZERO_TX)) {
                // Skip zero tx
                continue;
            }
            require(_transactions[outputs[i].encryptedAmount] == address(0), "Existed transaction");
            _transactions[outputs[i].encryptedAmount] = outputs[i].owner;
        }

        require(IPlonkVerifier(_verifier2).verifyProof(proof, [uint256(inputs[0]), uint256(inputs[1]), uint256(outputs[0].encryptedAmount), uint256(outputs[1].encryptedAmount), inAmount, outAmount]), "Invalid proof");
    }

    function getOwner(bytes32 encryptedAmount) public view returns (address) {
        return _transactions[encryptedAmount];
    }

}
