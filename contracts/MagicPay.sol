// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

import "./interfaces/IPlonkVerifier.sol";
import "./FeeManager.sol";

contract MagicPay is Ownable, FeeManager {
    using SafeERC20 for IERC20;

    struct Transaction {
        address owner;
        address token;
    }

    address[] public verifiers;
    mapping(bytes32 => Transaction) internal _transactions;

    uint256 public ZERO_TX =
        14744269619966411208579211824598458697587494354926760081771325075741142829156;

    struct Output {
        address owner;
        bytes32 encryptedAmount;
        bytes message;
    }

    event Transfer(
        address indexed from,
        address indexed to,
        address indexed token,
        bytes32 encryptedAmount
    );

    constructor(address[] memory verifierAddresses, uint256 outFee, address feeReceiver) FeeManager(outFee, feeReceiver) {
        verifiers = verifierAddresses;
    }

    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setOutFee(uint256 outFee) public override onlyOwner {
        _setOutFee(outFee);
    }
    function setFeeReceiver(address feeReceiver) public override onlyOwner {
        _setFeeReceiver(feeReceiver);
    }

    function magicPay(
        address token,
        bytes32[] calldata inputs,
        Output[] calldata outputs,
        uint256 inAmount,
        uint256 outAmount,
        address outReceiver,
        uint256[24] calldata proof
    ) external payable {
        require(inputs.length >= 2 && inputs.length <= 11, "Invalid outputs length");
        if (inAmount > 0) {
            if (token == address(0)) {
                require(msg.value == inAmount, "Invalid inAmount");
            } else {
                IERC20(token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    inAmount
                );
            }
        }
        for (uint256 i = 0; i < inputs.length; i++) {
            if (inputs[i] == bytes32(ZERO_TX)) {
                // Skip zero tx
                continue;
            }
            require(
                _transactions[inputs[i]].owner == msg.sender,
                "Invalid transaction owner"
            );
            require(
                _transactions[inputs[i]].token == token,
                "Invalid transaction token"
            );
            delete _transactions[inputs[i]];
        }

        for (uint256 i = 0; i < outputs.length; i++) {
            if (outputs[i].encryptedAmount == bytes32(ZERO_TX)) {
                // Skip zero tx
                continue;
            }
            require(
                _transactions[outputs[i].encryptedAmount].owner == address(0),
                "Existed transaction"
            );
            _transactions[outputs[i].encryptedAmount] = Transaction(
                outputs[i].owner,
                token
            );

            emit Transfer(
                msg.sender,
                outputs[i].owner,
                token,
                outputs[i].encryptedAmount
            );
        }

        {
            uint256[] memory pubSignals = new uint256[](inputs.length + 4);

            for (uint256 i = 0; i < inputs.length; i++) {
                pubSignals[i] = uint256(inputs[i]);
            }

            console.log("inputs.length", pubSignals.length);
            pubSignals[inputs.length] = uint256(outputs[0].encryptedAmount);
            pubSignals[inputs.length + 1] = uint256(outputs[1].encryptedAmount);
            pubSignals[inputs.length + 2] = inAmount;
            pubSignals[inputs.length + 3] = outAmount;

            bytes memory encodedPubSignals;
            assembly {
                let size := mul(expectedLength, 0x20) // Calculate size in bytes (32 bytes per uint256)
                encodedPubSignals := mload(0x40) // Get free memory pointer
                mstore(encodedPubSignals, expectedLength) // Set array length
                let dataStart := add(encodedPubSignals, 0x20)
                for { let i := 0 } lt(i, expectedLength) { i := add(i, 1) } {
                    mstore(add(dataStart, mul(i, 0x20)), mload(add(add(pubSignals, 0x20), mul(i, 0x20))))
                }
                mstore(0x40, add(encodedPubSignals, size)) // Update free memory pointer
            }

            string memory functionSignature = string(abi.encodePacked("verifyProof(uint256[24],uint256[", _uint2str(pubSignals.length), "])"));
            console.logBytes(
                abi.encodeWithSelector(
                    bytes4(keccak256(abi.encodePacked(functionSignature))), 
                    proof, 
                    pubSignals
                )
            );
            console.log(functionSignature);
            (bool success, bytes memory data) = address(verifiers[inputs.length - 2]).staticcall(
                abi.encodeWithSelector(
                    bytes4(keccak256(abi.encodePacked(functionSignature))), 
                    proof, 
                    pubSignals
                )
            );
            console.logBytes(data);
            require(success, "Failed to call verifier");
            require(abi.decode(data, (bool)), "Invalid proof");
        }

        if (outAmount > 0) {
            uint256 fee = outAmount * getOutFee() / 1000;
            if (token == address(0)) {
                payable(outReceiver).transfer(outAmount - fee);
                payable(getFeeReceiver()).transfer(fee);
            } else {
                IERC20(token).safeTransfer(outReceiver, outAmount -fee);
                IERC20(token).safeTransfer(getFeeReceiver(), fee);
            }
        }
    }

    function getTransaction(bytes32 encryptedAmount)
        public
        view
        returns (address, address)
    {
        return (
            _transactions[encryptedAmount].owner,
            _transactions[encryptedAmount].token
        );
    }

    fallback() external payable {}

    receive() external payable {}
}
