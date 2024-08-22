// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";
import {Will} from "../src/Will.sol";
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

        assertTrue(F.toAddress(B1) == address(T20), "b1 not root");
        assertTrue(F.getParentOf(B1) == B1, "b1 not b1 parent");

        vm.expectRevert();
        F.mint(B1, 2 ether);

        assertTrue(F.totalSupply(B1) == 0, "B1 expecte 0 supply");

        T20.approve(address(F), 2 ether);
        uint256 balance0 = T20.balanceOf(A1);
        uint256 balance0T = T20.balanceOf(address(F));
        F.mint(B1, 2 ether);
        uint256 balance1T = T20.balanceOf(address(F));
        uint256 balance1 = T20.balanceOf(A1);
        assertTrue((balance0 - 1 ether) > balance1, " not transfered");
        assertTrue(balance0T + 1 ether < balance1T, "did not get T20 bal");

        assertTrue(F.totalSupply(B1) == 2 ether, "supply mint missm");

        uint256 bal1 = F.balanceOf(A1, B1);
        assertTrue(bal1 == 2 ether, "Qty. mint missmatch");
        uint256 rootBal = F.totalSupply(F.toID(T20addr));

        B2 = F.spawnBranch(B1);
        vm.label(F.toAddress(B2), "B2fid");
        assertTrue(F.getParentOf(B2) == B1, "not parent-son");
        assertTrue(F.totalSupply(B2) == 0, "some pre minted");
        assertTrue(B2 < B1, "shloud be smaller");
        assertTrue(F.getParentOf(B2) == B1, "not expected parent");
        assertTrue(B1 != B2, "unexpected same");
        assertTrue(F.getParentOf(B1) == B1, "expected B1 root");

        uint256 t20_0b1 = T20.balanceOf(address(F));

        T20.approve(address(F), 2 ether);
        F.mint(B2, 2 ether);

        assertTrue(t20_0b1 == T20.balanceOf(address(F)), "core balance change");

        uint256 bal2 = F.balanceOf(A1, B2);
        assertTrue(bal2 == 2 ether, "Qty. mint missmatch");
        assertTrue(F.totalSupply(B2) == 2 ether, "supply mint missm");

        console.log("1 eth .. burn started");
        F.burn(B2, 1 ether);
        console.log("1 eth .. burn ended");

        assertTrue(F.totalSupply(B2) == 1 ether, "supply mint missm 2 ");

        bal1 = F.totalSupply(B1);
        F.burn(B1, 1 ether);
        bal2 = F.totalSupply(B1);
        assertTrue(bal2 < bal1, "no supply decrease");

        vm.stopPrank();
    }

    function testSimpleBurn() public {
        vm.startPrank(A1);

        T20.approve(address(F), 2 ether);
        F.mint(B1, 2 ether);
        assertTrue(T20.balanceOf(address(F)) == 2 ether, "t20 bal f");

        vm.warp(1000);
        assertTrue(F.totalSupply(B1) == 2 ether, "supply mint missm 1");
        uint256 mintedAmount = F.mintInflation(B1);
        assertTrue(mintedAmount == 0, "has minted some amount");
        assertTrue(F.totalSupply(B1) == 2 ether, "supply mint missm 2");

        uint256 balance1 = T20.balanceOf(A1);
        uint256 totalInternalPre = F.totalSupply(B1);
        uint256 FungiTotal20BalPre = T20.balanceOf(address(F));

        F.burn(B1, 1 ether);

        uint256 balance2 = T20.balanceOf(A1);
        uint256 totalInternalPost = F.totalSupply(B1);
        uint256 FungiTotal20BalPost = T20.balanceOf(address(F));

        assertTrue((balance1 + 1 ether - ((1 ether) / 100_00)) == balance2, "burn balance growth");

        ///@dev default tax rate
        assertTrue(FungiTotal20BalPost < FungiTotal20BalPre, "same on burn");

        console.log("PRE ... , POST ... ---", totalInternalPre, totalInternalPost);
        assertTrue(F.totalSupply(B1) == 1 ether, "supply mint missm 3");

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
        uint256 totalInternalPre = F.totalSupply(B1);
        uint256 FungiTotal20BalPre = T20.balanceOf(address(F));

        F.burn(B1, 1 ether);

        /// (4-1)

        uint256 balance2 = T20.balanceOf(A1);
        uint256 totalInternalPost = F.totalSupply(B1);
        uint256 FungiTotal20BalPost = T20.balanceOf(address(F));

        assertTrue(balance1 + 1 ether - (1 ether / 100_00) == balance2, "burn balance growth");

        /// @dev tax
        assertTrue(FungiTotal20BalPost < FungiTotal20BalPre, "same on burn");
        assertTrue(F.totalSupply(B1) == 3 ether, "supply mint missm");

        vm.stopPrank();
    }
}
