// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

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

    function testView0FetchData() public {
        testBasicInflation();
        vm.prank(A1);
        F.spawnBranch(B1);

        console.log("######### tesBasicInflationEnd() #######");
        (uint256[][2] memory AB, NodeState[] memory NS) = F.getInteractionDataOf(A1);

        assertTrue(AB.length > 0, "no basic balances");
        assertTrue(NS.length > 0, "no NS");
        assertTrue(NS[0].signals.length == NS[0].childrenNodes.length, "len mismatch 0 ");
        assertTrue(NS[1].signals.length == NS[1].childrenNodes.length, "len mismatch 1");
        assertTrue(NS[2].signals.length == NS[2].childrenNodes.length, "len mismatch 2");
    }

    function testPathBurn() public {
        testBasicInflation();
        address A100 = address(25600000000000);
        uint256 root = uint160(bytes20(address(T20)));
        uint256 b0 = T20.balanceOf(A1) / 2;
        vm.prank(A1);
        T20.transfer(A100, b0);
        vm.label(A100, "A100");

        vm.startPrank(A100);
        T20.approve(address(F), type(uint256).max - 1);
        uint256 b1 = b0 / 10;
        ////////////////////////////////
        uint256 snap1 = vm.snapshot(); //// 1 | 1 sept
        ///////////////////////////////
        uint256 beforeMintBurnRoot = T20.balanceOf(A100);

        F.mint(root, b1);
        assertTrue(F.balanceOf(A100, root) == b1, "balance root not b1");
        vm.warp(block.timestamp + 100000);

        F.mintInflation(B1);
        assertTrue(F.balanceOf(A100, root) == b1, "balance root not b1");

        F.burn(root, b1);
        assertTrue(beforeMintBurnRoot > T20.balanceOf(A100), "tax not withheld");

        vm.revertTo(snap1); //// 2 step

        F.mint(root, b1);
        F.mintMembership(root);
        uint256 root2 = F.spawnBranch(root);
        F.mint(root2, b1);
        vm.warp(block.timestamp + 100000);

        uint256 b2 = F.balanceOf(A100, root2);
        assertTrue(b1 == b2, "not same amount up");
        assertTrue(F.balanceOf(A100, root) == 0, "has root balance after push 0");
        assertTrue(F.balanceOf(A100, root2) > 1, "has balance after push 1");

        uint256 root3 = F.spawnBranch(root2);
        F.mint(root3, b2);

        assertTrue(F.balanceOf(A100, root2) == 0, "has balance after push 2");
        assertTrue(F.balanceOf(A100, root3) == b2, "has balance after push 1");

        ////////////////////////////////
        uint256 snap2 = vm.snapshot(); //// 1 | 1 sept
        ///////////////////////////////

        uint256 b_x2 = b2 / 2;
        F.burn(root3, b_x2);
        assertTrue(F.balanceOf(A100, root2) == F.balanceOf(A100, root3), "equal o");
        F.burn(root3, b_x2);
        assertTrue(F.balanceOf(A100, root3) == 0, "all bruned");
        assertTrue(F.totalSupplyOf(root3) == 0);
        assertTrue(F.balanceOf(A100, root2) > F.balanceOf(A100, root3), "equal o");

        vm.revertTo(snap2);

        F.burn(root3, b_x2);
        assertTrue(F.balanceOf(A100, root2) == F.balanceOf(A100, root3), "equal o");
        ///###
        F.burn(root2, b_x2);
        vm.warp(block.timestamp + 1_234_564);
        F.mintInflation(root3);
        assertTrue(F.totalSupplyOf(root3) > F.totalSupplyOf(root2), "no infl diff");
        assertTrue(F.totalSupplyOf(root3) > F.totalSupplyOf(root2), "inval default infl");
        F.mintInflation(root2);
        assertTrue(F.totalSupplyOf(root3) < F.totalSupplyOf(root2), "inval default infl");
        vm.warp((uint256(block.timestamp) + uint256(1_234_564) / 100_00));
        F.mintInflation(root3);
        assertFalse(F.totalSupplyOf(root3) > F.totalSupplyOf(root2), "inval default infl");

        vm.warp((uint256(block.timestamp) + 1_000_01));
        F.mintInflation(root3);
        assertTrue(F.totalSupplyOf(root3) > F.totalSupplyOf(root2), "inval default infl");

        ///###
        F.burn(root3, b_x2);
        assertFalse(F.balanceOf(A100, root2) == F.balanceOf(A100, root3), "! equal o");
        assertTrue(F.totalSupplyOf(root3) > 0);
        assertTrue(F.balanceOf(A100, root3) == 0, "has balance");

        F.burn(root2, F.balanceOf(A100, root2));

        b0 = T20.balanceOf(A100);
        F.burn(root, F.balanceOf(A100, root));

        assertTrue(b0 < T20.balanceOf(A100), "no refund");

        vm.revertTo(snap2); //// 2 step
        vm.warp((uint256(block.timestamp) + 1_000_01));
        F.mintInflation(root3);

        console.log("here gdfngj4353");
        F.burnPath(root3, F.balanceOf(A100, root3));

        vm.stopPrank();
    }
}
