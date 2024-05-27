// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {Will} from "../src/Will.sol";
import {Execution} from "../src/Execution.sol";

import {WillWe} from "../src/WillWe.sol";
import {IPowerProxy} from "../src/interfaces/IPowerProxy.sol";

import {InitTest} from "./Init.t.sol";

import {WillWeDeploy} from "../script/WillWeDeploy.s.sol";

contract LocalG is Test, TokenPrep, WillWeDeploy {
    IPowerProxy FoundingSafe;
    address deployer;

    function setUp() public override {
        super.setUp();

        // vm.createSelectFork(vm.envString("BASE_SepoliaRPC")); //
        super.run();
        deployer = 0x920CbC9893bF12eD967116136653240823686D9c;
        FoundingSafe = IPowerProxy(E.FoundationAgent());
    }

    function testContractsDeployed() public {
        assertTrue(address(FunFun).code.length > 1, "no code fun");
        assertTrue(address(E).code.length > 0, "no code E");
        assertTrue(address(F20).code.length > 0, "no code F20");
        assertTrue(address(FoundingSafe).code.length > 0, "no code safe");
    }

    function testFoundationAgent() public {
        assertTrue(address(FoundingSafe).code.length > 1, "code len of Safe 0");
        assertTrue(FoundingSafe.owner() == address(E), "Exe not owner");

        assertTrue(FunFun.getParentOf(FunFun.toID(address(FoundingSafe))) > 0, "no parent");
        assertTrue(
            FunFun.getParentOf(FunFun.getParentOf(FunFun.toID(address(FoundingSafe)))) > 0, "no for parent of founding"
        );
    }
}
