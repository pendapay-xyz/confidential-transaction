// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

abstract contract FeeManager {
    uint256 private _outFee;
    address private _feeReceiver;

    constructor (uint256 outFee, address feeReceiver) public {
        _outFee = outFee;
        _feeReceiver = feeReceiver;
    }

    function _setOutFee() internal {

    }
}
