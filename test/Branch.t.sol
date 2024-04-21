// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {RVT} from "../src/RVT.sol";
import {Execution} from "../src/Execution.sol";

import {Fun} from "../src/Fun.sol";

import {InitTest} from "./Init.t.sol";

contract BranchTests is Test, TokenPrep, InitTest {
    IERC20 T20;
    address T20addr;
    uint256 T20tid;

    function setUp() public override {
        super.setUp();
        T20 = IERC20(makeReturnERC20());
        vm.label(address(T20), "T20");

        T20addr = address(T20);
        T20tid = uint160(bytes20(T20addr));
    }

    function testZeroBalance() public {
        assertTrue(T20.balanceOf(address(22)) == 0, "balance");
    }

    function testCreateInstance() public {
        vm.startPrank(address(1));
        uint256 B1 = F.spawnRootBranch(T20addr);

        vm.expectRevert(Fungido.RootExists.selector);
        uint256 f1 = F.spawnRootBranch(T20addr);

        uint256 i0 = F.spawnBranch(B1);
        assertTrue(i0 > 0, "i0 is 0");

        vm.warp(block.timestamp + 100);
        uint256 i1 = F.spawnBranch(i0);

        uint256 ii2 = F.spawnBranch(i1);

        uint256 ix = F.spawnBranch(B1);
        console.log("i0, ix", i0, ix);
        assertTrue(i0 > ix, "i0 is 0 2");

        vm.stopPrank();
    }
}
