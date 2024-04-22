// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Fungido.sol";

import {RVT} from "../src/RVT.sol";
import {Execution} from "../src/Execution.sol";

import {BagBok} from "../src/BagBok.sol";

import {IFun} from "../src/interfaces/IFun.sol";

import {Membranes} from "../src/Membranes.sol";

import "forge-std/console.sol";

contract InitTest is Test {
    RVT public F20;
    BagBok public F;
    Membranes public M;
    address public E;

    address public A1;
    address public A2;
    address public A3;
    uint256 public A1pvk;
    uint256 public A2pvk;
    uint256 public A3pvk;

    function setUp() public virtual {
        address[] memory founders = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        (A1, A1pvk) = makeAddrAndKey("Alice1_aAndKey");
        (A2, A2pvk) = makeAddrAndKey("Alice2_aAndKey");
        (A3, A3pvk) = makeAddrAndKey("Alice3_aAndKey");

        founders[0] = address(A1);
        amounts[0] = 1 ether * 10_000_000;

        F20 = new RVT(10, 1, founders, amounts);
        M = new Membranes();
        E = address(new Execution(address(F20)));
        F = new BagBok(E, address(M));

        vm.label(address(F20), "F20");
        vm.label(address(E), "Execution");
        vm.label(address(F), "BagBok");
        vm.label(address(F20), "F20");
        vm.label(address(E), "Execution");
        vm.label(address(F), "Fun");
        vm.label(address(A1), "A1");
        vm.label(address(A2), "A2");
        vm.label(address(A3), "A3");
    }

    function testInit() public {
        assertTrue(address(E).code.length != 0, "Fungo failed to deploy");
    }

    function testOnePluSOne() public {
        assertTrue(1 + 1 == 2);
    }
}
