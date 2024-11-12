// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./MagicPay.sol";

contract ETHPay is MagicPay {
    constructor (address verifier2) public {
        __MagicPay_init(verifier2);
    }
    function pay2(bytes32[] calldata inputs, Output[] calldata outputs, uint256 inAmount, uint256 outAmount, uint256[24] calldata proof) public payable {
        if (inAmount > 0) {
            require(msg.value == inAmount, "Invalid inAmount");
        }

        _pay2(inputs, outputs, inAmount, outAmount, proof);

        if (outAmount > 0) {
            require(address(this).balance >= outAmount, "Invalid outAmount");
            payable(msg.sender).transfer(outAmount);
        }
    }
}
