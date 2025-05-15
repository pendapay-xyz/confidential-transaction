// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IGroth16Verifier2.sol";
import "./interfaces/IGroth16Verifier13.sol";
import "./libraries/LinkedList.sol";
import "./FeeManager.sol";

contract MagicPay is Ownable, FeeManager {
    using LinkedList for LinkedList.List;
    using SafeERC20 for IERC20;

    address private _verifier2;
    address private _verifier13;

    mapping(bytes32 => bytes) internal _messages;
    mapping(address => mapping(address => LinkedList.List))
        internal _transactions;

    uint256 public ZERO_TX =
        14744269619966411208579211824598458697587494354926760081771325075741142829156;

    struct Output {
        address owner;
        bytes32 encryptedAmount;
        bytes message;
    }

    struct Proof {
        uint[2] pA;
        uint[2][2] pB;
        uint[2] pC;
    }

    event Transfer(
        address indexed from,
        address indexed to,
        address indexed token,
        bytes32 encryptedAmount
    );

    event SetVerifier2(address verifier);
    event SetVerifier13(address verifier);

    constructor(
        address verifier2,
        address verifier13,
        uint256 withdrawFee,
        address feeReceiver
    ) FeeManager(withdrawFee, feeReceiver) {
        _verifier2 = verifier2;
        _verifier13 = verifier13;
    }

    function setVerifier2(address verifier) public onlyOwner {
        _verifier2 = verifier;
        emit SetVerifier2(verifier);
    }

    function setVerifier13(address verifier) public onlyOwner {
        _verifier13 = verifier;
        emit SetVerifier13(verifier);
    }

    function setWithdrawFee(uint256 withdrawFee) public override onlyOwner {
        _setWithdrawFee(withdrawFee);
    }

    function setFeeReceiver(address feeReceiver) public override onlyOwner {
        _setFeeReceiver(feeReceiver);
    }

    function magicPay(
        address token,
        bytes32[] calldata inputs,
        Output[2] calldata outputs,
        uint256 inAmount,
        uint256 outAmount,
        address outReceiver,
        Proof memory proof
    ) external payable {
        if (inAmount > 0) {
            if (token == address(0)) {
                require(msg.value >= inAmount, "Invalid inAmount");
            } else {
                IERC20(token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    inAmount
                );
            }
        }
        for (uint256 i = 0; i < inputs.length; i++) {
            LinkedList.List storage list = _transactions[msg.sender][token];
            if (inputs[i] == bytes32(ZERO_TX)) {
                // Skip zero tx
                continue;
            }
            // Check if the input transaction exists in remove function
            list.remove(inputs[i]);
        }

        for (uint256 i = 0; i < 2; i++) {
            if (outputs[i].encryptedAmount == bytes32(ZERO_TX)) {
                // Skip zero tx
                continue;
            }
            // Check if transaction already exists in push function
            _transactions[outputs[i].owner][token].pushBack(
                outputs[i].encryptedAmount
            );
            // store message for the transaction
            _messages[outputs[i].encryptedAmount] = outputs[i].message;

            if (msg.sender != outputs[i].owner) {
                // saving gas
                emit Transfer(
                    msg.sender,
                    outputs[i].owner,
                    token,
                    outputs[i].encryptedAmount
                );
            }
        }

        {
            if (inputs.length == 2) {
                bool isValidProof = IGroth16Verifier2(_verifier2)
                    .verifyProof(
                        proof.pA,
                        proof.pB,
                        proof.pC,
                        [
                            uint(inputs[0]),
                            uint(inputs[1]),
                            uint(outputs[0].encryptedAmount),
                            uint(outputs[1].encryptedAmount),
                            inAmount,
                            outAmount
                        ]
                    );

                require(isValidProof, "Invalid proof");
            } else if (inputs.length == 13) {
                bool isValidProof = IGroth16Verifier13(_verifier13)
                    .verifyProof(
                        proof.pA,
                        proof.pB,
                        proof.pC,
                        [
                            uint(inputs[0]),
                            uint(inputs[1]),
                            uint(inputs[2]),
                            uint(inputs[3]),
                            uint(inputs[4]),
                            uint(inputs[5]),
                            uint(inputs[6]),
                            uint(inputs[7]),
                            uint(inputs[8]),
                            uint(inputs[9]),
                            uint(inputs[10]),
                            uint(inputs[11]),
                            uint(inputs[12]),
                            uint(outputs[0].encryptedAmount),
                            uint(outputs[1].encryptedAmount),
                            inAmount,
                            outAmount
                        ]
                    );

                require(isValidProof, "Invalid proof");
            } else {
                revert("Invalid inputs");
            }
        }

        if (outAmount > 0) {
            uint256 fee = getWithdrawFee();
            require(
                msg.value == inAmount + fee,
                "Need to pay fee when withdraw"
            );
            payable(getFeeReceiver()).transfer(fee);
            if (token == address(0)) {
                payable(outReceiver).transfer(outAmount);
            } else {
                IERC20(token).safeTransfer(outReceiver, outAmount);
            }
        } else {
            require(msg.value == inAmount, "Only pay inAmount");
        }
    }

    function getVerifier2() public view returns (address) {
        return _verifier2;
    }

    function getVerifier13() public view returns (address) {
        return _verifier13;
    }

    function getTransactions(
        address owner,
        address token,
        bytes32 start,
        uint256 count
    ) public view returns (bytes32[] memory) {
        if (start == bytes32(0)) {
            start = _transactions[owner][token].head;
        }
        bytes32[] memory transactions = _transactions[owner][token].traverse(
            start,
            count
        );
        return transactions;
    }

    function _uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
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
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    fallback() external payable {}

    receive() external payable {}
}
