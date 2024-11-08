pragma circom 2.0.0;
include "transfer.circom";

component main {public [inputNullifiers, outputNullifiers, inPublicAmount, outPublicAmount]} = Transfer(2, 2);
