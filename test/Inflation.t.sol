// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {Fungo} from "../src/Fungo.sol";
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
        T20 = IERC20(makeReturnERC20());
        vm.label(address(T20), "T20");

        T20addr = address(T20);
        T20tid = uint160(bytes20(T20addr));

        A1 = address(1);
        A2 = address(2);
        A3 = address(3);

        vm.prank(address(1));
        console.log(address(F));
        B1 = F.spawnRootBranch(T20addr);
    }
}
