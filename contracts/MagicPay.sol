// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./interfaces/IPlonkVerifier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MagicPay {
    using SafeERC20 for IERC20;

    struct Profile {
        bool isInit;
        bytes encryptedPrivateKey;
        bytes publicKey;
    }

    struct Transaction {
        address owner;
        address token;
    }

    address private _verifier2;

    mapping(address => Profile) internal _profiles;
    mapping(bytes32 => Transaction) internal _transactions;

    uint256 public ZERO_TX =
        14744269619966411208579211824598458697587494354926760081771325075741142829156;

    struct Output {
        address owner;
        bytes32 encryptedAmount;
    }

    event Transfer(
        address indexed from,
        address indexed to,
        address indexed token,
        bytes32 encryptedAmount
    );

    constructor(address verifier2) {
        _verifier2 = verifier2;
    }

    function setProfile(
        bytes memory encryptedPrivateKey,
        bytes memory publicKey
    ) public {
        _profiles[msg.sender] = Profile(true, encryptedPrivateKey, publicKey);
    }

    function pay2(
        address token,
        bytes32[] calldata inputs,
        Output[] calldata outputs,
        uint256 inAmount,
        uint256 outAmount,
        address outReceiver,
        uint256[24] calldata proof,
        bytes memory
    ) external payable {
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

        require(
            IPlonkVerifier(_verifier2).verifyProof(
                proof,
                [
                    uint256(inputs[0]),
                    uint256(inputs[1]),
                    uint256(outputs[0].encryptedAmount),
                    uint256(outputs[1].encryptedAmount),
                    inAmount,
                    outAmount
                ]
            ),
            "Invalid proof"
        );
        if (outAmount > 0) {
            if (token == address(0)) {
                require(
                    address(this).balance >= outAmount,
                    "Invalid outAmount"
                );
                payable(outReceiver).transfer(outAmount);
            } else {
                IERC20(token).safeTransfer(outReceiver, outAmount);
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

    function getProfile(address owner) public view returns (Profile memory) {
        return _profiles[owner];
    }

    fallback() external payable {}

    receive() external payable {}
}
