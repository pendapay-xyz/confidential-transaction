// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./MagicPay.sol";

contract ETHPay is MagicPay {
    function pay2(bytes32[] calldata inputs, Output[] calldata outputs, uint256 inAmount, uint256 outAmount, uint256[24] calldata proof) public {

    }
}
