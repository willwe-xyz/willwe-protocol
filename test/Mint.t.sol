// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";
import {RVT} from "../src/RVT.sol";
import {Execution} from "../src/Execution.sol";

import {Fun} from "../src/Fun.sol";
import {InitTest} from "./Init.t.sol";

contract MintTest is Test, TokenPrep, InitTest {
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

        T20addr = address(T20);
        vm.label(address(F), "Fungi");
        T20tid = uint160(bytes20(T20addr));

        vm.prank(address(A1));
        B1 = F.spawnRootBranch(T20addr);
    }

    function testInitCheck() public {
        assertTrue(T20.balanceOf(address(22)) == 0, "balance");
        assertTrue(T20.balanceOf(A1) > 10, "no supply");
    }

    function testToAToI(uint256 x) public {
        vm.assume(x < type(uint160).max);
        address a = F.toAddress(x);
        assertTrue(address(uint160(x)) == a, "lostInTranslation1");
    }

    function testToAToI(address x) public {
        uint256 a = F.toID(x);
        assertTrue(x == address(uint160(a)), "lostInTranslation2");
    }

    function testRootID() public {
        uint256 t20id = F.toID(T20addr);
        assertTrue(B1 == t20id, "different rootID-addr");
        console.log("B1, f.toID(T20addr) --- ", B1, t20id);
    }

    function testToEqiv1() public {
        assertTrue(F.toAddress(B1) == F.toAddress(F.toID(F.toAddress(B1))), "non eq1");
    }

    function testToEqiv2(uint256 x) public {
        vm.assume(x < type(uint160).max);
        assertTrue(F.toAddress(x) == F.toAddress(F.toID(F.toAddress(x))), "n eq2");
    }

    function testSimpleMint() public {
        vm.startPrank(A1);
        vm.expectRevert();
        F.mint(B1, 2 ether);

        T20.approve(address(F), 2 ether);
        F.mint(B1, 2 ether);

        assertTrue(F.totalSupplyOf(B1) == 2 ether, "supply mint missm");

        uint256 bal1 = F.balanceOf(A1, B1);
        assertTrue(bal1 == 2 ether, "Qty. mint missmatch");

        uint256 rootBal = F.totalSupplyOf(F.toID(T20addr));

        B2 = F.spawnBranch(B1);
        assertTrue(F.getParentOf(B2) == B1, "not parent-son");

        assertTrue(B2 < B1, "shloud be smaller");

        F.mint(B2, 2 ether);
        uint256 bal2 = F.balanceOf(A1, B2);
        assertTrue(bal2 == 2 ether, "Qty. mint missmatch");
        assertTrue(F.totalSupplyOf(B2) == 2 ether, "supply mint missm");

        vm.stopPrank();
    }

    function testSimpleBurn() public {
        vm.startPrank(A1);

        T20.approve(address(F), 2 ether);
        F.mint(B1, 2 ether);

        vm.warp(1000);
        assertTrue(F.totalSupplyOf(B1) == 2 ether, "supply mint missm");

        uint256 balance1 = T20.balanceOf(A1);
        uint256 totalInternalPre = F.totalSupplyOf(B1);
        uint256 FungiTotal20BalPre = T20.balanceOf(address(F));

        F.burn(B1, 1 ether);

        uint256 balance2 = T20.balanceOf(A1);
        uint256 totalInternalPost = F.totalSupplyOf(B1);
        uint256 FungiTotal20BalPost = T20.balanceOf(address(F));

        assertTrue((balance1 + 1 ether - ((1 ether) / 100_00)) == balance2, "burn balance growth");

        ///@dev default tax rate
        assertTrue(FungiTotal20BalPost < FungiTotal20BalPre, "same on burn");

        console.log("PRE ... , POST ... ---", totalInternalPre, totalInternalPost);
        assertTrue(F.totalSupplyOf(B1) == 1 ether, "supply mint missm");

        vm.stopPrank();
    }

    function testLayerBurn() public {
        vm.startPrank(A1);

        T20.approve(address(F), 4 ether);
        F.mint(B1, 4 ether);

        uint256 branch2 = F.spawnBranch(B1);
        F.mint(branch2, 1 ether);

        uint256 branch3 = F.spawnBranch(branch2);
        F.mint(branch3, 1 ether);

        uint256 B02 = F.spawnBranch(B1);
        uint256 branch202 = F.spawnBranch(B02);

        F.mint(B02, 2 ether);
        F.mint(branch202, 1 ether);

        uint256 balance1 = T20.balanceOf(A1);
        uint256 totalInternalPre = F.totalSupplyOf(B1);
        uint256 FungiTotal20BalPre = T20.balanceOf(address(F));

        F.burn(B1, 1 ether);

        /// (4-1)

        uint256 balance2 = T20.balanceOf(A1);
        uint256 totalInternalPost = F.totalSupplyOf(B1);
        uint256 FungiTotal20BalPost = T20.balanceOf(address(F));

        assertTrue(balance1 + 1 ether - (1 ether / 100_00) == balance2, "burn balance growth");

        /// @dev tax
        assertTrue(FungiTotal20BalPost < FungiTotal20BalPre, "same on burn");
        assertTrue(F.totalSupplyOf(B1) == 3 ether, "supply mint missm");

        vm.stopPrank();
    }
}
