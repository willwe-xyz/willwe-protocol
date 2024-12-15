// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {Will} from "will/contracts/Will.sol";
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
    uint256 B11;
    uint256 B22;
    uint256 B21;

    function setUp() public override {
        super.setUp();
        vm.prank(A1);
        T20 = IERC20(makeReturnERC20());
        vm.label(address(T20), "T20");

        vm.prank(A1);
        B1 = F.spawnRootBranch(address(T20));
        vm.label(address(uint160(B1)), "B1root");

        vm.prank(A1);
        T20.approve(address(F), 10 ether);

        vm.prank(A1);
        B11 = F.spawnBranch(B1);
        vm.label(address(uint160(B2)), "B2root");

        vm.prank(A1);
        B22 = F.spawnBranch(B11);
        vm.label(address(uint160(B2)), "B22node");

        vm.prank(A1);
        B21 = F.spawnBranch(B11);
        vm.label(address(uint160(B21)), "B21node");

        vm.prank(A1);
        uint256 amt = T20.balanceOf(A1) / 2;
        vm.prank(A1);
        T20.transfer(A2, amt);

        vm.prank(A1);
        T20.approve(address(F), amt);

        vm.prank(A2);
        T20.approve(address(F), amt);
        vm.prank(A2);
        F.mint(B1, amt);
        vm.prank(A1);
        F.mint(B1, amt);

        vm.prank(A1);
        F.mint(B11, amt);

        vm.prank(A2);
        F.mint(B11, amt);

        vm.prank(A2);
        F.mintMembership(B11);
    }

    function testChecks() public {
        assertTrue(F.balanceOf(A1, B11) == F.balanceOf(A2, B11), "not same bal");
    }

    function twoPartiesEQRedist() public {
        // vm.startPrank(A1);

        // F.sendSignal(B11, signals);

        // vm.stopPrank();
    }
}
