// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Script.sol";
import {Fun} from "../src/Fun.sol";
import {Execution} from "../src/Execution.sol";

import {Membranes} from "../src/Membranes.sol";

import {RVT} from "../src/RVT.sol";
import {X20} from "../test/mock/Tokens.sol";

contract LineaDeployAndPopulate is Script {
    Fun FunFun;
    Execution E;
    Membranes M;
    RVT RVT20;
    X20 MockUSDC;

    address Normie1;
    address Normie2;
    address Normie3;

    function setUp() public {
        console.log("###############################");
        console.log("                                                             ");
        console.log("   Deploy script started for network : ", block.chainid);

        console.log("                                                             ");
        console.log("###############################");

        Normie1 = 0x7426936C6A7FE0C8B004D17918ab98ab651CC4d0;
        Normie2 = 0xb87aAc6b2C8Bf74053Dca1c05131f8037e340346;
        Normie3 = 0x04B87b4B5E5cAdee5c07fbe42F9b10b25a9F8a44;
    }

    function run() public {
        vm.startBroadcast(vm.envUint("fungo_PVK")); //// start 1
        address[] memory founders = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        founders[0] = address(0xF86bc3D323354359E6aEcf26202611Dd097aA0Fe);

        /// "equity"
        founders[1] = address(0xea779D765A263d9832106083D5426aa75E096109);
        /// "dao"
        amounts[0] = 1 ether * 10_000_000;
        amounts[1] = 1 ether * 10_000_000;

        RVT20 = new RVT(1000, 1, founders, amounts);

        E = new Execution(address(RVT20));
        M = new Membranes();

        FunFun = new Fun(address(E), address(M));

        RVT20.transfer(Normie1, 10 ether);
        RVT20.transfer(Normie2, 20 ether);
        RVT20.transfer(Normie3, 30 ether);

        MockUSDC = new X20();
        MockUSDC.transfer(Normie1, 11 ether);
        MockUSDC.transfer(Normie2, 12 ether);
        MockUSDC.transfer(Normie3, 13 ether);

        console.log("###############################");
        console.log("                                                             ");
        console.log("###############################");
        console.log("                                                             ");
        console.log("RootValueToken RVT20 deployed at : ", address(RVT20));
        console.log("                                                             ");
        console.log("###############################");
        console.log("                                                             ");
        console.log("###############################");

        console.log("                                                             ");

        console.log("                                                             ");

        console.log("Fun deployed at : ", address(FunFun));
        console.log("###############################");
        console.log("                                                             ");
        console.log("MockUSDC deployed at : ", address(MockUSDC));
        console.log("###############################");

        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("normie1")); //// start 1

        uint256 USDCid1 = FunFun.spawnRootBranch(address(MockUSDC));
        MockUSDC.approve(address(FunFun), type(uint256).max);
        FunFun.mint(USDCid1, 1 ether);

        vm.stopBroadcast();

        // vm.startBroadcast(vm.envUint("normie2")); //// start 1

        // MockUSDC.approve(address(FunFun), type(uint256).max);

        // FunFun.mint(USDCid1, 1 ether);

        // FunFun.mintMembership(USDCid1, Normie2);
        //         uint256 USDCid2 = FunFun.spawnBranch(USDCid1);
        // FunFun.mint(USDCid2, 1 ether);

        // vm.stopBroadcast();

        // vm.startBroadcast(vm.envUint("normie3")); //// start 1
        //         MockUSDC.approve(address(FunFun), type(uint256).max);

        // FunFun.mint(USDCid1, 3 ether);
        // FunFun.mint(USDCid2, 2 ether);

        // FunFun.mintMembership(USDCid1, Normie3);
        // FunFun.mintMembership(USDCid2, Normie3);
        //         uint256 USDCid3 = FunFun.spawnBranch(USDCid2);
        // FunFun.mint(USDCid3, 1 ether);

        // vm.stopBroadcast();
    }
}
