// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IGroth16Verifier.sol";
import "./FeeManager.sol";

contract MagicPay is Ownable, FeeManager {
    using SafeERC20 for IERC20;

    struct Transaction {
        address owner;
        address token;
    }

    address verifier;
    mapping(bytes32 => Transaction) internal _transactions;

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

    constructor(address[] memory verifierAddresses, uint256 outFee, address feeReceiver) FeeManager(outFee, feeReceiver) {
        verifier = verifierAddresses[0];
    }

    function setOutFee(uint256 outFee) public override onlyOwner {
        _setOutFee(outFee);
    }
    function setFeeReceiver(address feeReceiver) public override onlyOwner {
        _setFeeReceiver(feeReceiver);
    }

    function magicPay(
        address token,
        bytes32[2] calldata inputs,
        Output[2] calldata outputs,
        uint256 inAmount,
        uint256 outAmount,
        address outReceiver,
        Proof memory proof
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
        bool isValidProof = IGroth16Verifier(verifier).verifyProof(
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
