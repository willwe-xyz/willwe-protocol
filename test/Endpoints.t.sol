// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {Fun} from "../src/Fun.sol";
import {Execution} from "../src/Execution.sol";
import {SignatureQueue} from "../src/interfaces/IExecution.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {SignatureQueue, SQState, MovementType} from "../src/interfaces/IExecution.sol";

import {ISafe} from "../src/interfaces/ISafe.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {Fungo} from "../src/Fungo.sol";
import {InitTest} from "./Init.t.sol";

contract Endpoints is Test, TokenPrep, InitTest {
    IERC20 T1;
    IERC20 T2;

    uint256 rootBranchID;

    uint256 B1;
    uint256 B2;
    uint256 B11;
    uint256 B12;

    function setUp() public override {
        super.setUp();
        address[] memory founders = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        founders[0] = address(A1);
        amounts[0] = 1 ether * 10_000_000;

        T1 = IERC20(makeReturnERC20());
        vm.label(address(T1), "Token1");

        T2 = IERC20(makeReturnERC20());
        vm.label(address(T2), "Token2");

        vm.prank(A1);
        T1.approve(address(F), type(uint256).max);
        vm.prank(A1);
        T2.approve(address(F), type(uint256).max);
        vm.prank(A2);
        T2.approve(address(F), type(uint256).max);
        vm.prank(A2);
        T2.approve(address(F), type(uint256).max);

        vm.prank(address(1));
        T1.approve(address(F), type(uint256).max);

        vm.startPrank(A1);
        rootBranchID = F.spawnRootBranch(address(T1));

        B1 = F.spawnBranch(rootBranchID);
        B11 = F.spawnBranch(B1);
        B12 = F.spawnBranch(B1);

        B2 = F.spawnBranch(rootBranchID);

        vm.stopPrank();
    }

    function testSimpleDeposit() public {
        vm.prank(address(1));
        T1.transfer(A1, 1 ether + 1);
        assertTrue(B1 > 1);
        assertTrue(F.balanceOf(A1, rootBranchID) == 0, "unexpected balance");
        assertTrue(F.isMember(A1, rootBranchID), "branch creator should be member");

        uint256 before = T1.balanceOf(A1);

        vm.prank(A1);
        F.mint(rootBranchID, 1 ether);

        vm.prank(address(1));
        T1.transfer(address(F), 10 ether);

        vm.prank(A1);
        F.burn(rootBranchID, 1 ether);

        uint256 aaafter = T1.balanceOf(A1);
        console.log(before, aaafter, before - aaafter);
        ///@dev tax applied
        // assertTrue(before == aaafter, "before as after");
    }

    function testProposesNewMovement() public {
        if (block.chainid != 59140) return;

        testSimpleDeposit();
        console.log("########### new movement________________");

        bytes32 description = keccak256("this is a description");
        bytes memory data = abi.encodePacked("calldata");

        vm.startPrank(A1);

        vm.expectRevert(Execution.EmptyUnallowed.selector);
        F.proposeMovement(0, rootBranchID, 12, address(0), description, data);

        vm.expectRevert(Execution.NotExeAccOwner.selector);
        F.proposeMovement(1, rootBranchID, 12, address(1), description, data);

        address[] memory members = F.allMembersOf(rootBranchID);
        assertTrue(members.length > 0, "shoudl have members for majority");

        bytes32 moveHash = F.proposeMovement(2, rootBranchID, 12, address(0), description, data);
        bytes32 empty;
        assertTrue(empty != moveHash, "empty");
        SignatureQueue memory SQ = F.getSigQueue(moveHash);
        assertTrue(SQ.state == SQState.Initialized, "expected intiailized");
        assertTrue(SQ.Action.descriptionHash == description, "description mism");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");

        //   MovementType.AgentMajority : MovementType.EnergeticMajority;
        assertTrue(SQ.Action.category == MovementType.EnergeticMajority, "not type 2");

        address safe = SQ.Action.exeAccount;

        ISafe Safe = ISafe(safe);
        address[] memory ooo = Safe.getOwners();
        uint256 threshold = Safe.getThreshold();

        assertTrue(ooo.length == 1, "more than one owner for energetic type");
        assertTrue(ooo[0] == address(F.executionAddress()), "owner not ExeEngine");
        assertTrue(threshold == 1, "not 1 threshold");

        vm.stopPrank();
    }

    function testCreatesNodeEndpoint() public {
        if (block.chainid != 59140) return;

        testSimpleDeposit();
        console.log("########### new ENDPOINT________________");
        vm.startPrank(A1);

        bytes32 description = keccak256("this is a description");
        bytes memory data = abi.encodePacked("calldata");

        bytes32 moveHash = F.proposeMovement(1, rootBranchID, 12, address(0), description, data);
        SignatureQueue memory SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected intiailized");
        assertTrue(SQ.Action.descriptionHash == description, "description mism");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");

        assertTrue(SQ.Action.category == MovementType.AgentMajority, "not type 1");

        console.log("###################  AGAIN with prev exe______________");
        skip(block.timestamp + 10);
        description = keccak256("this is a description");
        data = abi.encodePacked("calldata");

        moveHash = F.proposeMovement(1, rootBranchID, 12, SQ.Action.exeAccount, description, data);
        SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected intiailized");
        assertTrue(SQ.Action.descriptionHash == description, "description mism");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");

        assertTrue(SQ.Action.category == MovementType.AgentMajority, "not type 1");

        console.log("###################  Again with exe type 2______________");
        skip(block.timestamp + 10);
        description = keccak256("this is a description");
        data = abi.encodePacked("calldata");

        moveHash = F.proposeMovement(2, rootBranchID, 12, SQ.Action.exeAccount, description, data);
        SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected intiailized");
        assertTrue(SQ.Action.descriptionHash == description, "description mism");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");

        assertTrue(SQ.Action.category == MovementType.EnergeticMajority, "not type 1");

        vm.stopPrank();
    }

    function testCreatesSoloEndpoint() public {
        if (block.chainid != 59140) return;

        vm.startPrank(A1);

        address endpoint = F.createEndpointForOwner(rootBranchID, A1);

        assertTrue(ISafe(endpoint).getThreshold() == 1, "unexpected threshold");
        assertTrue(ISafe(endpoint).isOwner(A1), "expected owner");

        uint256 membershipID = F.membershipID(F.toID(endpoint));
        console.log("these should be the same  -------  GGFYASG& ----", uint160(endpoint) % 10 ether, membershipID);

        vm.label(A1, "A1User");

        assertTrue(F.balanceOf(A1, membershipID) == 1, "the id owner");
        assertTrue(F.isMember(A1, membershipID), "expected member");

        vm.stopPrank();
    }

    function testExecutesSignatureQueue() public {
        ///---
    }

    function testSubmitsSignatures() public {
        ///---
    }
}
