// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import {Will} from "../src/Will.sol";
import "forge-std/console.sol";

import {X20} from "./mock/Tokens.sol";

contract MintTest is Test {
    Will Will20;

    address A;
    address B;
    address C;

    X20 Xtoken1;
    X20 Xtoken2;
    X20 Xtoken3;

    function setUp() public {
        vm.warp(22224444);

        A = address(111);
        B = address(222);
        C = address(333);

        address[] memory tokenGenesisHaves = new address[](3);
        uint256[] memory endowmentAmts = new uint256[](3);

        tokenGenesisHaves[0] = A;
        tokenGenesisHaves[1] = B;
        tokenGenesisHaves[2] = C;

        endowmentAmts[0] = 1 ether;
        endowmentAmts[1] = 20 ether;
        endowmentAmts[2] = 100 ether;

        Will20 = new Will(123456789, 10, tokenGenesisHaves, endowmentAmts);

        Xtoken1 = new X20();
        Xtoken2 = new X20();
        Xtoken3 = new X20();
    }

    function testBasic() public {
        uint256 price = Will20.currentPrice();
        vm.warp(block.timestamp + 1);
        uint256 price2 = Will20.currentPrice();

        assertTrue(price < price2, "price increase expected");
        assertTrue(price + 10 gwei == price2, "price increase expected");

        assertTrue(Will20.burnReturns(1 ether) == 0, "no underlying");
        vm.deal(address(Will20), Will20.totalSupply() * 1 ether);
        assertTrue(Will20.burnReturns(1) == 1 ether, "expected 1 for 1");
    }

    function _handOutTokens(uint256 x) public {
        console.log("###_-- handing out tokens --_### ||| with multiplier ::: ", x);

        vm.startPrank(address(1));
        Xtoken1.transfer(A, x * 1);
        Xtoken1.transfer(B, x * 2);
        Xtoken1.transfer(C, x * 3);

        Xtoken2.transfer(A, x * 1);
        Xtoken2.transfer(B, x * 2);
        Xtoken2.transfer(C, x * 3);

        Xtoken3.transfer(A, x * 1);
        Xtoken3.transfer(B, x * 2);
        Xtoken3.transfer(C, x * 3);
        vm.stopPrank();
    }

    function testArbitraryUnderlying(uint256 xBalance) public {
        uint256 totalS = Xtoken1.balanceOf(address(1)) / 10;
        console.log("#testArbitraryUnderlying###################################");
        vm.assume(xBalance < totalS / 9);
        vm.assume(xBalance > 10 gwei);

        _handOutTokens(xBalance);

        address Y = address(46534564356);
        vm.prank(Y);
        assertEq(Xtoken1.balanceOf(Y), 0, "expected no balance");
        assertEq(Xtoken1.balanceOf(address(Will20)), 0, "expected no balance 2");

        vm.prank(address(1));
        Xtoken1.transfer(address(Will20), 100 ether);

        assertTrue(address(Y).balance == 0, "has ether. why?");
        deal(Y, 10 ether);

        uint256 snap1 = vm.snapshot();

        /// simple eth-only

        uint256 cost = Will20.mintCost(1 ether);
        vm.deal(Y, cost);
        vm.prank(Y);
        Will20.mint{value: cost}(1 ether);

        vm.warp(block.timestamp + 10);

        uint256 snap2 = vm.snapshot();

        uint256 b1 = address(Y).balance;

        vm.prank(Y);
        uint256 howMuchToB = Will20.balanceOf(Y);

        uint256 snap3 = vm.snapshot();

        vm.prank(Y);
        uint256 burnReturned = Will20.simpleBurn(howMuchToB / 2);

        assertTrue(address(Y).balance >= b1, "get no juice from burn");
        assertTrue(cost > burnReturned, "not sponsored");

        vm.revertTo(snap3);

        vm.deal(address(Will20), address(Will20).balance + burnReturned * 100);

        vm.prank(Y);
        uint256 secondB = Will20.simpleBurn(howMuchToB / 2);
        assertTrue(secondB > burnReturned, "expected more");

        vm.revertTo(snap2);

        uint256 proportion = Will20.balanceOf(Y);

        assertTrue(Xtoken1.balanceOf(Y) == 0, "has token1 balance");

        /// 1
        address[] memory tokenGenesisHaves = new address[](1);
        tokenGenesisHaves[0] = address(Xtoken1);
        assertTrue(Xtoken1.balanceOf(address(Will20)) >= 1 ether, "has no balance");
        howMuchToB = Will20.balanceOf(Y) / 2;
        b1 = Xtoken1.balanceOf(Y);
        console.log("bf half supply burn");
        vm.prank(Y);
        Will20.deconstructBurn(howMuchToB, tokenGenesisHaves);
        console.log("after half supply burn");
        uint256 b2 = Xtoken1.balanceOf(Y);
        assertFalse(Xtoken1.balanceOf(Y) == 0, "has no balance");
        console.log("post b2, pre b1", b2, b1);
        assertTrue(b2 > b1, "none recovered");

        /// 2
    }

    function testMintFrE() public {
        address Y = address(465345643561111111);
        vm.startPrank(Y);
        deal(Y, 100 ether);
        uint256 cost = Will20.mintCost(100);
        uint256 b0 = Will20.balanceOf(Y);
        uint256 snap0 = vm.snapshot();

        Will20.mintFromETH{value: cost}();

        assertTrue(Will20.balanceOf(Y) == b0 + 100, "unexpec. sequence bal 1");

        vm.revertTo(snap0);

        address(Will20).call{value: cost}("");
        assertTrue(Will20.balanceOf(Y) == b0 + 100, "unexpec. sequence bal 2");
    }
}
