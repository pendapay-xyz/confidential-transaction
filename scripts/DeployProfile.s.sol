// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../contracts/Profile.sol";

contract DeployMagicPayScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deploying Profile contract with deployer address: ", deployer);

        vm.startBroadcast(deployerPrivateKey);
        Profile profile = new Profile();
        console.log("Profile deployed at address: ", address(profile));
        vm.stopBroadcast();
    }
}
