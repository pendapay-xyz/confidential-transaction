// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

abstract contract FeeManager {
    uint256 private _transactionFee;
    address private _feeReceiver;

    constructor(uint256 transactionFee, address feeReceiver) {
        _transactionFee = transactionFee;
        _feeReceiver = feeReceiver;
    }

    event FeeChanged(uint256 newFee);
    event FeeReceiverChanged(address newFeeReceiver);

    function _setTransactionFee(uint256 transactionFee) internal {
        _transactionFee = transactionFee;
        emit FeeChanged(transactionFee);
    }

    function _setFeeReceiver(address feeReceiver) internal {
        _feeReceiver = feeReceiver;
        emit FeeReceiverChanged(feeReceiver);
    }

    function setTransactionFee(uint256 transactionFee) public virtual;
    function setFeeReceiver(address feeReceiver) public virtual;

    function getTransactionFee() public view returns (uint256) {
        return _transactionFee;
    }

    function getFeeReceiver() public view returns (address) {
        return _feeReceiver;
    }
}
