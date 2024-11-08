// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract MagicPay {
    address private _verifier2;
    mapping (bytes32 => address) internal _transactions;

    struct Output {
        address owner;
        bytes32 encryptedAmount;
        bytes message;
    }

    function _pay(bytes32[] calldata inputs, Output[] calldata outputs, uint256 outAmount) internal {
        for (uint256 i = 0; i < inputs.length; i++) {
            require(_transactions[inputs[i]] == msg.sender, "Invalid transaction");
            delete _transactions[inputs[i]];
        }

        for (uint256 i = 0; i < outputs.length; i++) {
            require(_transactions[outputs[i].encryptedAmount] == address(0), "Existed transaction");
            _transactions[outputs[i].encryptedAmount] = outputs[i].owner;
        }

        if (outAmount > 0) {
            (bool success, ) = msg.sender.call{value: outAmount}("");
            require(success, "Transfer failed.");
        }
    }
}
