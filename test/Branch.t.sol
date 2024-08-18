// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {Will} from "../src/Will.sol";
import {Execution} from "../src/Execution.sol";

import {Fun} from "../src/Fun.sol";

import {InitTest} from "./Init.t.sol";

contract BranchTests is Test, TokenPrep, InitTest {
    IERC20 T20;
    address T20addr;
    uint256 T20tid;

    uint256 ii2;
    uint256 ix;
    uint256 i1;

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
        i1 = F.spawnBranch(i0);

        ii2 = F.spawnBranch(i1);

        ix = F.spawnBranch(B1);
        console.log("i0, ix", i0, ix);
        assertTrue(i0 > ix, "i0 is 0 2");

        vm.stopPrank();
    }

    function testFetchesPath() public {
        testCreateInstance();
        vm.prank(address(1));
        uint256 b = F.spawnBranch(ii2);
        vm.prank(address(1));
        uint256 c = F.spawnBranch(b);
        assertTrue(F.getFidPath(c).length > 2, "path too short or none");

        assertTrue(F.getParentOf(c) == b, "unexpected parent");
        assertTrue(F.getParentOf(b) > 0, "unregistered b ");
        assertTrue(T20addr == address(uint160(F.getFidPath(c)[0])), "path [0] not root");
                vm.prank(address(1));
        T20.approve(address(F), type(uint256).max );
                vm.prank(address(1));

        F.mintPath(c, 100);


    }
}
