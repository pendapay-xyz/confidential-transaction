// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "../contracts/MagicPay.sol";
import "../contracts/verifiers/verifier2.sol";

contract DeployMagicPayScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        PlonkVerifier verifier = new PlonkVerifier();
        MagicPay magicPay = new MagicPay(address(verifier), 0, address(0));
        console.log("MagicPay deployed at address: ", address(magicPay));
        vm.stopBroadcast();
    }
}
