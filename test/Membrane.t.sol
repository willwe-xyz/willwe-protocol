// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Fungo} from "../src/Fungo.sol";
import {Execution} from "../src/Execution.sol";

import {Fun} from "../src/Fun.sol";
import {InitTest} from "./Init.t.sol";

contract MembraneTests is Test, InitTest {
    ERC20 X20;
    ERC721 X721;

    function setUp() public override {
        super.setUp();
        X20 = new ERC20("AERC20", "18");
        X721 = new ERC721("B721", "symbol");

        vm.label(address(X20), "X20");
        vm.label(address(X721), "X721");
    }

    function testCreatesMembrane() public {
        address[] memory tokens_ = new address[](1);
        uint256[] memory balances_ = new uint256[](1);
        string memory meta_ = "http://meta.eth";

        uint256 snap1 = vm.snapshot();

        tokens_[0] = address(X20);
        uint256 mID = F.createMembrane(tokens_, balances_, meta_);
        assertTrue(mID > type(uint160).max, "expected 256");

        vm.revertTo(snap1);

        tokens_[0] = address(X20);
        balances_[0] = 123 ether;
        mID = F.createMembrane(tokens_, balances_, meta_);
        assertTrue(mID > type(uint160).max, "expected 256");

        vm.revertTo(snap1);

        tokens_[0] = address(X20);
        balances_[0] = 123 ether;
        balances_ = new uint256[](3);
        vm.expectRevert();
        mID = F.createMembrane(tokens_, balances_, meta_);

        vm.revertTo(snap1);

        tokens_ = new address[](0);
        balances_ = new uint256[](0);
        vm.expectRevert();
        mID = F.createMembrane(tokens_, balances_, meta_);
    }
}
