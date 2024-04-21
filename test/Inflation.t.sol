// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {RVT} from "../src/RVT.sol";
import {Execution} from "../src/Execution.sol";

import {Fun} from "../src/Fun.sol";

import {InitTest} from "./Init.t.sol";

contract InflationTest is Test, TokenPrep, InitTest {
    IERC20 T20;
    address T20addr;
    uint256 T20tid;

    uint256 B1;
    uint256 B2;
    uint256 Branch2ID;

    function setUp() public override {
        super.setUp();
        vm.prank(A1);
        T20 = IERC20(makeReturnERC20());
        vm.label(address(T20), "T20");

        vm.prank(A1);
        B1 = F.spawnRootBranch(address(T20));

        vm.prank(A1);
        T20.approve(address(F), 10 ether);

        vm.prank(A1);
        F.mint(B1, 2 ether);

        vm.prank(A1);
        B1 = F.spawnBranch(B1);
    }

    function testBasicInflation() public {
        vm.prank(A1);
        F.mint(B1, 1 ether);
        F.mintInflation(B1);

        console.log("1 - T0 default inflation, balance", F.inflationOf(B1), F.totalSupplyOf(B1));
        uint256 snap1 = vm.snapshot();

        vm.warp(block.timestamp + 1000);

        uint256[] memory signals = new uint256[](2);
        signals[1] = 1_000;

        vm.prank(A1);
        F.sendSignal(B1, signals);

        //////////////////////////////////////
        signals[1] = 1 ether;
        vm.prank(A1);
        F.sendSignal(B1, signals);
        console.log("2 - T1 default inflation, balance", F.inflationOf(B1), F.totalSupplyOf(B1));
        uint256 Bt0 = F.totalSupplyOf(B1);
        console.log("+ 100 seconds");
        vm.warp(block.timestamp + 100);

        F.mintInflation(B1);
        uint256 Bt1 = F.totalSupplyOf(B1);

        console.log("2 - T1 default inflation, balance", F.inflationOf(B1), F.totalSupplyOf(B1));
        console.log(Bt1 - Bt0, "diff after 100 sec. of 1 ether inflation");
        assertTrue((Bt1 - Bt0) == 1 ether * 1 gwei * 100, "inflation mism or not in gwei");
    }
}
