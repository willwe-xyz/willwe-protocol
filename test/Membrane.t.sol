// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {X20} from "./mock/Tokens.sol";
import {RVT} from "../src/RVT.sol";
import {Execution} from "../src/Execution.sol";

import {Fun} from "../src/Fun.sol";
import {InitTest} from "./Init.t.sol";

import {IPowerProxy} from "../src/interfaces/IPowerProxy.sol"; 

contract MembraneTests is Test, InitTest {
    X20 X20token;
    ERC721 X721;

    uint256 rootBranch;
    uint256 B1;

    function setUp() public override {
        super.setUp();
        X20token = new X20();
        X721 = new ERC721("B721", "symbol");

        vm.label(address(X20token), "X20token");
        vm.label(address(X721), "X721");

        vm.prank(A1);
        rootBranch = F.spawnRootBranch(address(X20token));
        vm.prank(A1);
        B1 = F.spawnBranch(rootBranch);

        vm.prank(address(this));
        X20token.transfer(A1, 1 ether);
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
        F.mint(rootBranch, 1 ether);

        vm.prank(A1);
        F.mint(B1, 1 ether);

        vm.prank(A1);
        F.sendSignal(B1, signal);

        assertTrue(F.getMembraneOf(B1) == membraneId, "! this membrane");

        uint256 snap = vm.snapshot();

        vm.expectRevert();
        vm.prank(address(5));
        F.mintMembership(B1, address(5));

        vm.prank(address(1));
        X20token.transfer(address(5), 2 ether);

        vm.prank(address(5));
        F.mintMembership(B1, address(5));

        vm.prank(address(5));
        X20token.transfer(address(10), 2 ether);

        assertTrue(F.isMember(address(5), B1), "not member");

        vm.prank(address(69));
        F.membershipEnforce(address(5), B1);

        assertFalse(F.isMember(address(5), B1), "is member");
    }

    function testProxyControl() public {
        testEnforceM();

        vm.prank(A1);
        IPowerProxy P = IPowerProxy(F.createEndpointForOwner(B1, A1));
        
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




}
