// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Script.sol";
import {Fun} from "../src/Fun.sol";
import {Execution} from "../src/Execution.sol";

import {Fungo} from "../src/Fungo.sol";

contract FungoDeploy is Script {
    Fun FunFun;
    Execution E;
    Fungo F20;

    function setUp() public {
        console.log("###############################");
        console.log("                                                             ");
        console.log("   Deploy script started for network : ", block.chainid);

        console.log("                                                             ");
        console.log("###############################");
    }

    function run() public {
        address[] memory founders = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        founders[0] = address(0xF86bc3D323354359E6aEcf26202611Dd097aA0Fe);
        amounts[0] = 1 ether * 10_000_000;

        F20 = new Fungo(10, 1, founders, amounts);

        vm.startBroadcast(vm.envUint("testnetPVK")); //// start 1
        E = new Execution(address(F20));
        FunFun = new Fun(address(E));
        console.log("###############################");

        console.log("Fun deployed at : ", address(FunFun));
        console.log("###############################");

        vm.stopBroadcast();
    }
}
