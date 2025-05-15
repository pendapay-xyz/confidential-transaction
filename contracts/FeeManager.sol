// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

abstract contract FeeManager {
    uint256 private _withdrawFee;
    address private _feeReceiver;

    constructor(uint256 withdrawFee, address feeReceiver) {
        _withdrawFee = withdrawFee;
        _feeReceiver = feeReceiver;
    }

    event FeeChanged(uint256 newFee);
    event FeeReceiverChanged(address newFeeReceiver);

    function _setWithdrawFee(uint256 withdrawFee) internal {
        _withdrawFee = withdrawFee;
        emit FeeChanged(withdrawFee);
    }

    function _setFeeReceiver(address feeReceiver) internal {
        _feeReceiver = feeReceiver;
        emit FeeReceiverChanged(feeReceiver);
    }

    function setWithdrawFee(uint256 withdrawFee) public virtual;
    function setFeeReceiver(address feeReceiver) public virtual;

    function getWithdrawFee() public view returns (uint256) {
        return _withdrawFee;
    }

    function getFeeReceiver() public view returns (address) {
        return _feeReceiver;
    }
}
