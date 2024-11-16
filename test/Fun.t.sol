// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import {Fun} from "../src/Fun.sol";
import {TokenPrep} from "./mock/Tokens.sol";

// import {SQState, MovementType, Movement, SignatureQueue} from "../src/interfaces/IFungi.sol";
// import {ISafe} from "../src/interfaces/ISafe.sol";
import {Will} from "../src/Will.sol";

import {Execution} from "../src/Execution.sol";
import {NodeState} from "../src/interfaces/IExecution.sol";
import {Fun} from "../src/Fun.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {InitTest} from "./Init.t.sol";
import "forge-std/console.sol";

contract FunTests is Test, TokenPrep, InitTest {
    IERC20 T1;
    IERC20 T2;
    uint256 public rootBranchID;

    uint256 B1;
    uint256 B2;
    uint256 B11;
    uint256 B12;
    uint256 B22;

    function setUp() public virtual override {
        super.setUp();
        vm.warp(block.timestamp + 2345);
        vm.prank(address(1234567));

        T1 = IERC20(makeReturnERC20());
        vm.prank(address(1234567));

        T2 = IERC20(makeReturnERC20());

        vm.prank(A1);
        T1.approve(address(F), type(uint256).max);
        vm.prank(A1);
        T2.approve(address(F), type(uint256).max);
        vm.prank(A2);
        T2.approve(address(F), type(uint256).max);
        vm.prank(A2);
        T2.approve(address(F), type(uint256).max);

        vm.prank(address(1));
        T1.approve(address(F), type(uint256).max);

        vm.startPrank(A1);
        rootBranchID = F.spawnRootBranch(address(T1));

        B1 = F.spawnBranch(rootBranchID);
        vm.label(address(uint160(B1)), "B1");

        B11 = F.spawnBranch(B1);
        vm.label(address(uint160(B11)), "B11");
        B12 = F.spawnBranch(B1);
        vm.label(address(uint160(B12)), "B12");

        B2 = F.spawnBranch(rootBranchID);
        vm.label(address(uint160(B2)), "B2");
        B22 = F.spawnBranch(B2);
        vm.label(address(uint160(B22)), "B22");
        B12 = F.spawnBranch(B1);
        vm.label(address(uint160(B12)), "B12");

        B2 = F.spawnBranch(rootBranchID);
        vm.label(address(uint160(B2)), "B2");
        B22 = F.spawnBranch(B2);
        vm.label(address(uint160(B22)), "B22");

        console.log("T1 ERC20 (u160) value setup --- ", uint160(address(T1)));

        console.log("RootBranch value setup --- ", rootBranchID);

        console.log("B1 value setup --- ", B1);
        console.log("B2 value setup --- ", B2);
        console.log("B11 value setup --- ", B11);
        console.log("B12 value setup --- ", B12);
        console.log("B22 value setup --- ", B22);

        vm.warp(block.timestamp + 120333);

        vm.stopPrank();
    }

    function testCreateMembrane() public returns (uint256 mID) {
        address[] memory tokens = new address[](1);
        tokens[0] = address(T1);
        uint256[] memory balances = new uint256[](1);
        balances[0] = 1;
        string memory meta = "http://urltoveryImportantDataAndDescriptionfrfr.com";
        mID = M.createMembrane(tokens, balances, meta);
        assertTrue(mID > type(uint160).max, "expected membraneId bigger than address");
    }

    function testChangesMembrane() public returns (uint256 snap2) {
        uint256 membraneID = testCreateMembrane();
        vm.prank(address(1));
        T1.transfer(A1, 100 ether);
        uint256 funBalance = T1.balanceOf(address(A1));

        vm.prank(A1);
        F.mint(rootBranchID, 10 ether);
        assertTrue(F.balanceOf(A1, rootBranchID) == 10 ether, "expected balance 10 eth");

        vm.prank(A1);
        F.mint(B1, 2 ether);
        uint256[] memory signal = new uint256[](2);

        vm.prank(address(uint160(uint256(keccak256(abi.encode("not member"))))));
        vm.warp(block.timestamp + 1);
        vm.expectRevert(Fun.Noise.selector);
        F.sendSignal(B1, signal);

        vm.startPrank(A1);

        signal = new uint256[](F.getChildrenOf(B1).length + 2);
        signal[0] = 234523345466;
        vm.warp(block.timestamp + 1);
        vm.expectRevert(Fun.MembraneNotFound.selector);
        F.sendSignal(B1, signal);

        signal[0] = membraneID;

        uint256 snap = vm.snapshot();
        vm.warp(block.timestamp + 1);

        F.sendSignal(B1, signal);
        vm.warp(block.timestamp + 1);

        console.log(F.totalSupply(B1), F.balanceOf(A1, B1), "total supply | Balance of A1");

        assertEq(F.getMembraneOf(B1), membraneID, "expected mid");

        // vm.revertTo(snap);
        // signal[1] = 232;
        // vm.warp(block.timestamp + 1);
        // F.sendSignal(B1, signal);
        // assertTrue(F.inflationOf(B1) == signal[1] * 1 gwei);

        // vm.stopPrank();

        // snap2 = vm.snapshot();
    }

    function testInflates() public {
        vm.warp(block.timestamp + 120333);

        vm.prank(address(1));
        T1.transfer(A1, 100 ether);
        uint256 funBalance = T1.balanceOf(address(A1));

        vm.startPrank(A1);

        F.mint(rootBranchID, 10 ether);
        assertTrue(F.balanceOf(A1, rootBranchID) == 10 ether, "expected balance 10 eth");
        uint256 rootInflation = F.inflationOf(rootBranchID);
        console.log("default inflation rate rootBranch :  - ", rootInflation);

        F.mint(B1, 2 ether);
        uint256 B1inflation = F.inflationOf(B1);

        uint256 defaultRateB = F.inflationOf(B1);
        console.log("default inflation rate B1 - ", defaultRateB);
        uint256 totalSupB1 = F.totalSupply(B1);
        F.mintInflation(B1);
        vm.warp(block.timestamp + 120333);
        F.mintInflation(B1);
        uint256 totalSuppostB1 = F.totalSupply(B1);
        console.log("supply B1 before - after inflation : - ", totalSupB1, totalSuppostB1);

        assertTrue(totalSuppostB1 > totalSupB1 + B1inflation * 120332, "expected inflation print");
        console.log("diffff - ", totalSuppostB1 - totalSupB1);

        vm.stopPrank();
    }

    function testRedistriInflation() public {
        testInflates();

        vm.prank(address(1));
        T1.transfer(A2, 200 ether);

        vm.prank(A2);
        T1.approve(address(F), type(uint256).max / 2);
        vm.prank(A2);
        F.mint(rootBranchID, 10 ether);

        vm.startPrank(A1);
        uint256[] memory childrenOf = F.getChildrenOf(B1);
        uint256[] memory signals = new uint256[](childrenOf.length + 2);
        console.log("B1 has this amount of children :  -- ", childrenOf.length);
        signals[0] = 0;
        signals[1] = 3245;
        signals[2] = 90_00;
        signals[3] = 10_00;
        vm.warp(block.timestamp + 120333);

        uint256 initBalanceB11 = F.balanceOf(address(uint160(B11)), B1);
        uint256 initBalanceB12 = F.balanceOf(address(uint160(B12)), B1);
        console.log("initiat balances of B11 - B12", initBalanceB11, initBalanceB12);
        vm.warp(block.timestamp + 234225);

        F.sendSignal(B1, signals);
        address[] memory tokens = new address[](1);
        uint256[] memory balances = new uint256[](1);
        tokens[0] = address(T1);
        balances[0] = 1 ether;
        uint256 newmembraneID = M.createMembrane(tokens, balances, "meta");

        vm.warp(block.timestamp + 234225);
        signals[0] = newmembraneID;
        signals[2] = 88_00;
        signals[3] = 0;
        signals[4] = 12_00;

        F.sendSignal(B1, signals);

        console.log(B11, B12);
        console.log(childrenOf[0], childrenOf[1], childrenOf[2]);
        assertTrue(childrenOf[0] == B11, "index assumption false 1");
        assertTrue(childrenOf[2] == B12, "index assumption false 2");

        uint256 postBalanceB11 = F.balanceOf(address(uint160(B11)), B1);
        uint256 postBalanceB12 = F.balanceOf(address(uint160(B12)), B1);

        console.log("post balances of B11 - B12", postBalanceB11, postBalanceB12);
        assertTrue(F.getParentOf(B11) == B1, "expected rel");
        console.log("parent of B11 - - parent ", B11, F.getParentOf(B11));
        console.log("parent of B12  - - ", B12, F.getParentOf(B12));

        assertTrue(
            F.balanceOf(address(uint160(B11)), B1) > (F.balanceOf(address(uint160(B12)), B1) * 4),
            "expected percentage matter"
        );

        vm.warp(block.timestamp + 11536000);
        F.redistribute(B12);

        assertTrue(
            F.balanceOf(address(uint160(B12)), B1) > (F.balanceOf(address(uint160(B11)), B1)),
            "not only smaller redistributed"
        );

        vm.warp(block.timestamp + (223422 * 6));
        F.redistribute(B11);

        /////////// @dev order of operations matter. this is a bug.

        uint256 b11last = F.balanceOf(address(uint160(B11)), B1);
        uint256 b12last = F.balanceOf(address(uint160(B12)), B1);
        console.log("b11last - b12last, 000", b11last, b12last);

        assertFalse(F.getParentOf(B11) == F.getParentOf(F.getParentOf(B11)), "");
        F.redistribute(B11);
        b11last = F.balanceOf(address(uint160(B11)), B1);
        b12last = F.balanceOf(address(uint160(B12)), B1);
        console.log("b11last - b12last, 222", b11last, b12last);

        assertTrue(
            F.balanceOf(address(uint160(B11)), B1) > (F.balanceOf(address(uint160(B12)), B1)),
            "expected back to default"
        );

        vm.stopPrank();
    }

    function testFidLineage() public {
        uint256[] memory fids = F.getFidPath(B22);
        assertTrue(fids.length == 2, "fid has len");
        assertTrue(fids[0] == F.getParentOf(fids[0]), "first id not root");
        assertTrue(fids[0] == rootBranchID, "expecte root");
        assertTrue(fids[1] == B2, "expected parent");
    }

    function testMintPath() public {
        vm.prank(address(1));
        T1.transfer(A2, 10 ether);

        vm.prank(address(A2));
        T1.approve(address(F), 10 ether);

        uint256 b22_1 = F.balanceOf(A2, B22);
        uint256 b2_1 = F.balanceOf(A2, F.getParentOf(B22));

        vm.assertTrue(T1.balanceOf(A2) > 1 ether, "not enough balance");

        vm.prank(A2);
        F.mintPath(B22, 1 ether);

        uint256 b22_2 = F.balanceOf(A2, B22);
        uint256 b2_2 = F.balanceOf(A2, F.getParentOf(B22));

        assertTrue(b22_1 + 1 ether >= b22_2, "diff not constant1");
        assertTrue(b2_1 + 1 ether >= b2_2, "diff not constant2");
    }

    function testRedistributePath() public {
        // Run the existing inflation test to set up the initial state
        testRedistriInflation();

        vm.warp(block.timestamp + 1000);

        // Get the path from root to B12
        uint256[] memory path = new uint256[](3);
        path[0] = rootBranchID;
        path[1] = B1;
        path[2] = B12;

        // Record balances before redistribution
        uint256[] memory balancesBefore = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            balancesBefore[i] = F.totalSupply(path[i]);
            console.log("Balance before redistribution for node", path[i], ":", balancesBefore[i]);
        }

        F.getFidPath(B12);
        // Perform redistribution along the path
        vm.prank(A1);
        uint256 distributedAmt = F.redistributePath(B12);

        // Check redistribution results
        bool inflationMinted;
        for (uint256 i = 0; i < 3; i++) {
            uint256 balanceAfter = F.totalSupply(path[i]);
            console.log("Balance after redistribution for node", path[i], ":", balanceAfter);
            if (balanceAfter > balancesBefore[i]) inflationMinted = true;

            assertTrue(balanceAfter >= balancesBefore[i], "Total supply should not decrease after redistribution");
        }

        assertTrue(inflationMinted, "No inflation was minted along the path");
        assertTrue(distributedAmt > 0, "Distributed amount should be greater than zero");

        // Verify the path
        assertTrue(F.getParentOf(B12) == B1, "B1 should be parent of B12");
        assertTrue(F.getParentOf(B1) == rootBranchID, "rootBranchID should be parent of B1");

        // Check balances of B11 and B12 after path redistribution
        uint256 b11FinalBalance = F.balanceOf(address(uint160(B11)), B1);
        uint256 b12FinalBalance = F.balanceOf(address(uint160(B12)), B1);
        console.log("Final balance of B11:", b11FinalBalance);
        console.log("Final balance of B12:", b12FinalBalance);

        // Verify that the redistribution along the path didn't disrupt the expected balance relationship
        assertTrue(
            b11FinalBalance > b12FinalBalance, "B11 balance should still be greater than B12 after path redistribution"
        );
    }
}
