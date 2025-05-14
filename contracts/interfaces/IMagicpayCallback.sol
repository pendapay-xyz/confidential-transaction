// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

interface IMagicPayCallback {
    function onReceiveMagicPay(bytes32 transaction, address from, address token, uint256 encryptedAmount) external;
}
