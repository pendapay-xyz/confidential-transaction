pragma circom 2.0.0;
include "transfer.circom";

component main {public [inPublicAmount, outPublicAmount]} = Transfer(5, 2);
