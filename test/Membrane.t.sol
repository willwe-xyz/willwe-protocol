// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {X20} from "./mock/Tokens.sol";
import {Will} from "will/contracts/Will.sol";
import {Execution} from "../src/Execution.sol";

import {Fun} from "../src/Fun.sol";
import {InitTest} from "./Init.t.sol";

import {IPowerProxy} from "../src/interfaces/IPowerProxy.sol";

contract MembraneTests is Test, InitTest {
    X20 X20token;
    ERC721 X721;

    uint256 rootNode;
    uint256 B1;
    uint256 B2;

    function setUp() public override {
        super.setUp();
        X20token = new X20();
        X721 = new ERC721("B721", "symbol");

        vm.label(address(X20token), "X20token");
        vm.label(address(X721), "X721");

        vm.prank(A1);
        rootNode = F.spawnRootNode(address(X20token));
        vm.prank(A1);
        B1 = F.spawnNode(rootNode);
        vm.prank(A1);
        B2 = F.spawnNode(rootNode);

        vm.prank(address(this));
        X20token.transfer(A1, 10 ether);
        X20token.transfer(A2, 5 ether);
        X20token.transfer(A3, 2 ether);

        vm.prank(A1);
        X20token.approve(address(F), 10 ether);
    }

    function testCreatesMembrane() public returns (uint256 mID) {
        address[] memory tokens_ = new address[](1);
        uint256[] memory balances_ = new uint256[](1);
        string memory meta_ = "http://meta.eth";

        uint256 snap1 = vm.snapshot();

        tokens_[0] = address(X20token);
        mID = M.createMembrane(tokens_, balances_, meta_);
        assertTrue(mID > type(uint160).max, "expected 256");

        vm.revertTo(snap1);

        tokens_[0] = address(X20token);
        balances_[0] = 123 ether;
        mID = M.createMembrane(tokens_, balances_, meta_);
        assertTrue(mID > type(uint160).max, "expected 256");

        vm.revertTo(snap1);

        tokens_[0] = address(X20token);
        balances_[0] = 123 ether;
        balances_ = new uint256[](3);
        vm.expectRevert();
        mID = M.createMembrane(tokens_, balances_, meta_);

        vm.revertTo(snap1);

        tokens_ = new address[](0);
        balances_ = new uint256[](0);
        meta_ = "";
        vm.expectRevert();
        mID = M.createMembrane(tokens_, balances_, meta_);
    }

    function testEnforceM() public {
        address[] memory tokens_ = new address[](1);
        uint256[] memory balances_ = new uint256[](1);
        string memory meta_ = "http://meta.eth";

        tokens_[0] = address(X20token);
        balances_[0] = 1 ether;
        uint256 membraneId = M.createMembrane(tokens_, balances_, meta_);

        uint256[] memory signal = new uint256[](F.getChildrenOf(B1).length + 2);
        signal[0] = membraneId;

        vm.prank(A1);
        X20token.approve(address(F), 100 ether);

        vm.prank(A1);
        F.mint(rootNode, 1 ether);

        vm.prank(A1);
        F.mint(B1, 1 ether);

        vm.prank(A1);
        F.sendSignal(B1, signal);

        assertTrue(F.getMembraneOf(B1) == membraneId, "! this membrane");

        uint256 snap = vm.snapshot();

        vm.expectRevert();
        vm.prank(address(5));
        F.mintMembership(B1);

        vm.prank(address(1));
        X20token.transfer(address(5), 2 ether);

        vm.prank(address(5));
        F.mintMembership(B1);

        uint256 snapfor_renounce = vm.snapshot();

        vm.prank(address(5));
        X20token.transfer(address(10), 2 ether);

        assertTrue(F.isMember(address(5), B1), "not member");

        vm.prank(address(69));
        F.membershipEnforce(address(5), B1);

        assertFalse(F.isMember(address(5), B1), "is member");

        vm.revertTo(snapfor_renounce);
        assertTrue(F.isMember(address(5), B1));
        vm.prank(address(5));
        F.membershipEnforce(address(5), B1);
        assertFalse(F.isMember(address(5), B1), "renonce fail");
    }

    function testMembershipConditions() public {
        // Create a membrane with X20token requirement
        address[] memory tokens = new address[](1);
        uint256[] memory balances = new uint256[](1);
        tokens[0] = address(X20token);
        balances[0] = 1 ether;
        uint256 membraneId = M.createMembrane(tokens, balances, "X20 Requirement");

        // Set membrane for B1
        uint256[] memory signal = new uint256[](F.getChildrenOf(B1).length + 2);
        signal[0] = membraneId;
        vm.prank(A1);
        F.mintPath(B1, 2 ether);
        vm.prank(A1);
        F.sendSignal(B1, signal);

        assertTrue(F.balanceOf(A1, B1) > F.totalSupply(B1) / 2, "A1 should have more than half of the total supply");
        assertTrue(F.getMembraneOf(B1) == membraneId, "membrane not changed 0");

        // A2 should be able to mint membership (has 5 ether of X20token)
        vm.startPrank(A2);
        X20token.approve(address(F), 1 ether);
        F.mintMembership(B1);
        vm.stopPrank();
        assertTrue(F.isMember(A2, B1), "A2 should be a member");

        // A3 should be able to mint membership (has 2 ether of X20token)
        vm.startPrank(A3);
        X20token.approve(address(F), 1 ether);
        F.mintMembership(B1);
        vm.stopPrank();
        assertTrue(F.isMember(A3, B1), "A3 should be a member");

        uint256 snap1 = vm.snapshot();

        tokens = new address[](2);
        balances = new uint256[](2);

        tokens[0] = A2;
        tokens[1] = A1;

        balances[1] = 1;
        balances[0] = uint256(uint160(A2));

        membraneId = M.createMembrane(tokens, balances, "blacklist whitelist");
        vm.warp(block.timestamp + 100);
        // Set membrane for B1
        signal = new uint256[](F.getChildrenOf(B1).length + 2);
        signal[0] = membraneId;
        vm.prank(A1);
        F.sendSignal(B1, signal);

        assertTrue(F.getMembraneOf(B1) == membraneId, "membrane not changed 1");
        assertTrue(F.isMember(A1, B1), "A1 should still be member");

        vm.prank(A2);
        F.membershipEnforce(A1, B1);
        assertFalse(F.isMember(A1, B1), "A1 should no longer be member");

        vm.prank(A1);
        assertFalse(F.isMember(A1, B1), "A1 should not be a member");
    }

    function testProxyControl() public {
        testEnforceM();

        vm.prank(A1);
        IPowerProxy P = IPowerProxy(payable(F.createEndpointForOwner(B1, A1)));

        assertTrue(P.owner() == A1, "not expected owner");
        assertTrue(P.implementation() == address(0), "has Implementation");

        vm.expectRevert();
        P.setImplementation(address(1));

        vm.prank(A1);
        P.setImplementation(address(1));
        assertTrue(P.implementation() == address(1), "impl is ! 1");

        vm.prank(A1);
        P.setOwner(address(1));
        assertTrue(P.implementation() == address(1), "impl is ! 1");
        assertTrue(P.owner() == address(1), "owner no 1");
    }

    function testMembraneSignalPressureAccounting() public {
        // Create first membrane
        address[] memory tokens = new address[](1);
        uint256[] memory balances = new uint256[](1);
        tokens[0] = address(X20token);
        balances[0] = 1 ether;
        uint256 membrane1 = M.createMembrane(tokens, balances, "First Membrane");

        // Create second membrane
        uint256 membrane2 = M.createMembrane(tokens, balances, "Second Membrane");

        // Setup user balance and approve
        vm.prank(A1);
        F.mintPath(B1, 5 ether);

        // Signal first membrane
        uint256[] memory signal = new uint256[](F.getChildrenOf(B1).length + 2);
        signal[0] = membrane1;
        vm.prank(A1);
        F.sendSignal(B1, signal);

        // Wait some time
        vm.warp(block.timestamp + 100);

        // Signal second membrane
        signal[0] = membrane2;
        vm.prank(A1);
        F.sendSignal(B1, signal);

        // Verify membrane changed
        assertTrue(F.getMembraneOf(B1) == membrane2, "membrane should be updated");
    }
}
