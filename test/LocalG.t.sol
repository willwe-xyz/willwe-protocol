// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {RVT} from "../src/RVT.sol";
import {Execution} from "../src/Execution.sol";

import {Fun} from "../src/Fun.sol";

import {InitTest} from "./Init.t.sol";

contract LocalG is Test, TokenPrep, InitTest {
    function setUp() public override {
        super.setUp();
    }

    function activLG() public {
        F.setControl(address(this));
        F.gasMultiplier(address(594969), 3);
        F.taxPolicyPreference(address(1), 1000);
    }
}
