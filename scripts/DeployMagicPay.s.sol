// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../contracts/MagicPay.sol";
import "../contracts/verifiers/verifier2.sol";

contract DeployMagicPayScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        Groth16Verifier2 verifier2 = new Groth16Verifier2();
        MagicPay magicPay = new MagicPay(verifier2, address(0) 0, vm.addr(deployerPrivateKey));
        console.log("MagicPay deployed at address: ", address(magicPay));
        vm.stopBroadcast();
    }
}
