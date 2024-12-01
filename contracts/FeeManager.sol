// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

abstract contract FeeManager {
    uint256 private _outFee;
    address private _feeReceiver;

    constructor(uint256 outFee, address feeReceiver) {
        _outFee = outFee;
        _feeReceiver = feeReceiver;
    }

    event FeeChanged(uint256 newFee);
    event FeeReceiverChanged(address newFeeReceiver);

    function _setOutFee(uint256 outFee) internal {
        _outFee = outFee;
        emit FeeChanged(outFee);
    }

    function _setFeeReceiver(address feeReceiver) internal {
        _feeReceiver = feeReceiver;
        emit FeeReceiverChanged(feeReceiver);
    }

    function setOutFee(uint256 outFee) public virtual;
    function setFeeReceiver(address feeReceiver) public virtual;
}
