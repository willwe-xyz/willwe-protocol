// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {RVT} from "../src/RVT.sol";
import {Execution} from "../src/Execution.sol";

import {BagBok} from "../src/BagBok.sol";
import {ISafe} from "../src/interfaces/ISafe.sol";

import {InitTest} from "./Init.t.sol";

import {BagBokDeploy} from "../script/BagBokDeploy.s.sol";

contract LocalG is Test, TokenPrep, BagBokDeploy {
    ISafe FoundingSafe;
    address deployer;

    function setUp() public override {
        super.setUp();

        uint256 degenChain = vm.createSelectFork(vm.envString("DEGEN_RPC"), 7115176); //
        // uint256 degenChainBfDeploy = vm.createSelectFork(vm.envString("DEGEN_RPC"), 8376584); // 8376585

        super.run();
        deployer = 0x920CbC9893bF12eD967116136653240823686D9c;
        FoundingSafe = ISafe(E.FoundationAgent());
    }

    function testContractsDeployed() public {
        assertTrue(address(FunFun).code.length > 1, "no code fun");
        assertTrue(address(E).code.length > 0, "no code E");
        assertTrue(address(F20).code.length > 0, "no code F20");
        assertTrue(address(FoundingSafe).code.length > 0, "no code safe");
    }

    function testFoundationAgent() public {
        assertTrue(address(FoundingSafe).code.length > 1, "code len of Safe 0");
        FoundingSafe.getChainId();
        FoundingSafe.getThreshold();
        FoundingSafe.VERSION();
        assertTrue(FoundingSafe.isOwner(address(E)), "E not owner");
        vm.prank(address(E));
        address[] memory owners = new address[](1);
        owners[0] = address(E);
        vm.expectRevert();
        FoundingSafe.setup(owners, 1, address(0), abi.encodePacked(""), address(0), address(0), 0, address(0));
        assertTrue(F20.balanceOf(deployer) == 0, "deployer has balance");
        assertTrue(F20.balanceOf(address(FoundingSafe)) > F20.totalSupply() / 3, "safe F20 issue");
        assertTrue(FoundingSafe.isOwner(address(E)), "setup f");
        assertTrue(FoundingSafe.getOwners().length == 1, "not one owner");
        assertTrue(FoundingSafe.getOwners()[0] == address(E), "Execution not owner");
        console.log(E.FoundationAgent());
    }
}
