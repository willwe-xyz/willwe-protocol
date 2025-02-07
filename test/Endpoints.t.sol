// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import {Fun} from "../src/Fun.sol";
import {Execution} from "../src/Execution.sol";
import {SignatureQueue, IExecution, Movement, LatentMovement} from "../src/interfaces/IExecution.sol";
import {TokenPrep} from "./mock/Tokens.sol";
import {SignatureQueue, SQState, MovementType} from "../src/interfaces/IExecution.sol";
import {Movement, Call, NodeState} from "../src/interfaces/IExecution.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Will} from "will/contracts/Will.sol";
import {InitTest} from "./Init.t.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {IPowerProxy} from "../src/interfaces/IPowerProxy.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract Endpoints is Test, TokenPrep, InitTest {
    using ECDSA for bytes32;

    IERC20 T1;
    IERC20 T2;

    uint256 rootBranchID;

    uint256 B1;
    uint256 B2;
    uint256 B11;
    uint256 B12;

    address receiver;

    uint256 snapSig1;
    uint256 snapSig2;

    bytes32 constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant MOVEMENT_TYPEHASH = keccak256(
        "Movement(uint8 category,address initiatior,address exeAccount,uint256 viaNode,uint256 expiresAt,bytes32 descriptionHash,bytes executedPayload)"
    );

    bytes32 DOMAIN_SEPARATOR;

    function setUp() public override {
        super.setUp();
        vm.prank(address(1));
        T1 = IERC20(makeReturnERC20());
        vm.label(address(T1), "Token1");

        T2 = IERC20(makeReturnERC20());
        vm.label(address(T2), "Token2");

        vm.prank(A1);
        T1.approve(address(F), type(uint256).max);
        vm.prank(A1);
        T2.approve(address(F), type(uint256).max);

        vm.prank(A2);
        T1.approve(address(F), type(uint256).max);
        vm.prank(A2);
        T2.approve(address(F), type(uint256).max);

        vm.prank(A3);
        T1.approve(address(F), type(uint256).max);
        vm.prank(A3);
        T2.approve(address(F), type(uint256).max);

        vm.startPrank(A1);
        rootBranchID = F.spawnRootBranch(address(T1));

        B1 = F.spawnBranch(rootBranchID);
        B11 = F.spawnBranch(B1);
        B12 = F.spawnBranch(B1);

        B2 = F.spawnBranch(rootBranchID);

        vm.stopPrank();

        vm.prank(A2);
        F.mintMembership(rootBranchID);

        vm.prank(A3);
        F.mintMembership(rootBranchID);

        vm.startPrank(address(1));

        T1.transfer(A1, 10 ether);
        T1.transfer(A2, 10 ether);
        T1.transfer(A3, 10 ether);

        vm.stopPrank();

        receiver = address(bytes20(type(uint160).max / 2));

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, keccak256("WillWe"), keccak256("1"), block.chainid, address(E))
        );
    }

    function testSimpleDeposit() public {
        vm.prank(address(1));
        T1.transfer(A1, 1 ether + 1);

        assertTrue(B1 > 1);
        assertTrue(F.balanceOf(A1, rootBranchID) == 0, "unexpected balance");

        uint256 before = T1.balanceOf(A1);

        vm.prank(A1);
        F.mint(rootBranchID, 1 ether);

        vm.prank(address(1));
        T1.transfer(address(F), 10 ether);

        vm.prank(A1);
        F.burn(rootBranchID, 1 ether);

        uint256 aaafter = T1.balanceOf(A1);
        console.log(before, aaafter, before - aaafter);
    }

    function testEnergTxIni() public {
        vm.skip(false);
        vm.prank(address(1));
        T1.transfer(A1, 1 ether);

        vm.prank(address(1));
        T1.transfer(A2, 2.1 ether);

        vm.prank(address(1));
        T1.transfer(A3, 3 ether);

        vm.startPrank(A1);
        F.mint(rootBranchID, 1 ether);
        F.mint(B1, 0.9 ether);
        vm.stopPrank();

        vm.startPrank(A2);
        F.mint(rootBranchID, 1 ether);
        F.mint(B1, 1 ether);
        vm.stopPrank();

        vm.startPrank(A3);
        F.mint(rootBranchID, 2 ether);
        F.mint(B1, 1.2 ether);
        vm.stopPrank();
    }

    function testProposesNewMovement() public returns (bytes32 moveHash) {
        testSimpleDeposit();
        console.log("########### new movement________________");

        bytes32 description = keccak256("this is a description");
        bytes memory data = _getCallData();

        vm.startPrank(A1);

        vm.expectRevert(Execution.NoMovementType.selector);
        F.startMovement(0, B2, 3, address(0), description, data);

        vm.expectRevert(Execution.EmptyUnallowed.selector);
        F.startMovement(1, B2, 0, address(0), description, data);

        vm.expectRevert(Execution.NotExeAccOwner.selector);
        F.startMovement(1, B2, 12, address(1), description, data);

        address[] memory members = F.allMembersOf(B2);
        assertTrue(members.length > 0, "should have members for majority");

        moveHash = F.startMovement(2, B2, 12, address(0), description, data);

        assertTrue(uint256(moveHash) > 0, "empty hash returned");
        SignatureQueue memory SQ = F.getSigQueue(moveHash);
        assertTrue(SQ.state == SQState.Initialized, "expected initialized");
        assertTrue(SQ.Action.descriptionHash == description, "description mismatch");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");
        assertTrue(SQ.Action.category == MovementType.EnergeticMajority, "not type 2");

        vm.stopPrank();
        return moveHash;
    }

    function _getCallData() public returns (bytes memory call) {
        Call memory S;
        S.target = address(address(F20));
        bytes memory data = abi.encodeWithSelector(IERC20.transfer.selector, receiver, 0.1 ether);
        S.callData = data;

        Call[] memory calls = new Call[](1);
        calls[0] = S;
        call = abi.encodeWithSelector(IPowerProxy.tryAggregate.selector, true, calls);
    }

    function testCreatesNodeEndpoint() public {
        if (block.chainid != 59140) return;

        testSimpleDeposit();
        console.log("########### new ENDPOINT________________");
        vm.startPrank(A1);

        bytes32 description = keccak256("this is a description");
        bytes memory data = _getCallData();

        bytes32 moveHash = F.startMovement(1, rootBranchID, 12, address(0), description, data);
        SignatureQueue memory SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected initialized");
        assertTrue(SQ.Action.descriptionHash == description, "description mismatch");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");
        assertTrue(SQ.Action.category == MovementType.AgentMajority, "not type 1");

        console.log("###################  AGAIN with prev exe______________");
        skip(block.timestamp + 10);
        description = keccak256("this is a description");

        moveHash = F.startMovement(1, rootBranchID, 12, SQ.Action.exeAccount, description, data);
        SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected initialized");
        assertTrue(SQ.Action.descriptionHash == description, "description mismatch");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");
        assertTrue(SQ.Action.category == MovementType.AgentMajority, "not type 1");

        console.log("###################  Again with exe type 2______________");
        skip(block.timestamp + 10);
        description = keccak256("this is a description");

        moveHash = F.startMovement(2, rootBranchID, 12, SQ.Action.exeAccount, description, data);
        SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected initialized");
        assertTrue(SQ.Action.descriptionHash == description, "description mismatch");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");
        assertTrue(SQ.Action.category == MovementType.EnergeticMajority, "not type 2");

        vm.stopPrank();
    }

    function testCreatesSoloEndpoint() public {
        if (block.chainid != 59140) return;

        vm.startPrank(A1);

        address endpoint = F.createEndpointForOwner(rootBranchID, A1);

        uint256 membershipID = F.membershipID(F.toID(endpoint));
        console.log("these should be the same  -------  GGFYASG& ----", uint160(endpoint) % 10 ether, membershipID);

        vm.label(A1, "A1User");

        assertTrue(F.balanceOf(A1, membershipID) == 1, "the id owner");
        assertTrue(F.isMember(A1, membershipID), "expected member");

        NodeState memory N = F.getNodeData(rootBranchID, A1);
        assertEq(N.basicInfo[10], Strings.toHexString(endpoint), "expected endpoint in node data w user");
        assertEq(F.allMembersOf((F.toID(A1) + rootBranchID))[0], endpoint, "expected endpoint");

        vm.stopPrank();
    }

    function _signHash(uint256 signerPVK_, Movement memory movement) internal view returns (bytes memory signature) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("WillWe")),
                keccak256(bytes("1")),
                block.chainid,
                address(E)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Movement(uint8 category,address initiatior,address exeAccount,uint256 viaNode,uint256 expiresAt,bytes32 descriptionHash,bytes executedPayload)"
                ),
                movement.category,
                movement.initiatior,
                movement.exeAccount,
                movement.viaNode,
                movement.expiresAt,
                movement.descriptionHash,
                keccak256(movement.executedPayload)
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPVK_, hash);
        signature = abi.encodePacked(r, s, v);

        console.log("Generated signature length:", signature.length);
        return signature;
    }

    function _getStructsForHash()
        public
        returns (SignatureQueue memory SQ, Movement memory M, bytes memory STX, bytes32 move)
    {
        move = testProposesNewMovement();
        console.log(vm.toString(move));
        assertTrue(uint256(move) > 0, "no hash");

        SQ = F.getSigQueue(move);
        M = SQ.Action;
        STX = M.executedPayload;

        assertTrue(M.exeAccount != address(0), "safe is 0x0");
        vm.prank(address(1));
        T1.transfer(M.exeAccount, 3 ether);
    }

    function testSubmitsSignatures() public returns (bytes32 move) {
        (SignatureQueue memory SQ, Movement memory M, bytes memory STX, bytes32 m) = _getStructsForHash();
        move = m;
        assertTrue(uint256(IExecution(E).hashMessage(M)) == uint256(move), "Movement hash mismatch");

        bytes[] memory signatures;
        address[] memory signers;

        vm.expectRevert(Execution.EXEC_ZeroLen.selector);
        F.submitSignatures(move, signers, signatures);

        signers = new address[](3);
        signatures = new bytes[](3);

        vm.expectRevert(Execution.EXEC_A0sig.selector);
        F.submitSignatures(move, signers, signatures);

        signers[0] = A1;
        signers[1] = A2;
        signers[2] = A3;
        signatures[0] = _signHash(A1pvk, M);
        signatures[1] = _signHash(A2pvk, M);
        signatures[2] = _signHash(A3pvk, M);

        snapSig1 = vm.snapshot();

        assertFalse(F.isMember(A2, B2), "A2 should not be a member of B2");
        vm.prank(A2);
        F.mintMembership(B2);
        assertTrue(F.isMember(A2, B2), "A2 should be a member of B2");

        assertFalse(F.isMember(A3, B2), "A3 should not be a member of B2");
        vm.prank(A3);
        F.mintMembership(B2);
        assertTrue(F.isMember(A3, B2), "A3 should be a member of B2");
        assertTrue(F.isMember(A1, B2), "A1 should be a member of B2");

        vm.prank(A1);
        F.mintPath(B2, 1 ether);

        vm.prank(A2);
        F.mintPath(B2, 1 ether);

        vm.prank(A3);
        F.mintPath(B2, 1 ether);

        bool isValid = F.isQueueValid(move);
        assertFalse(F.isQueueValid(move), "Queue should not be valid yet");

        console.log("Submitting signatures...");
        F.submitSignatures(move, signers, signatures);
        console.log("Signatures submitted.");

        SQ = F.getSigQueue(move);

        console.log("Signature Queue length:", SQ.Signers.length);
        console.log("Expected length: 3");

        assertTrue(M.viaNode == B2, "Unexpected node");
        assertTrue(SQ.Action.viaNode == B2, "Expected B2 as viaNode");
        assertTrue(SQ.Signers.length == SQ.Sigs.length, "Length mismatch between Signers and Sigs");
        assertTrue(SQ.Signers.length == 3, "Unexpected signature length");

        for (uint256 i = 0; i < SQ.Signers.length; i++) {
            console.log("Signer", i, ":", SQ.Signers[i]);
        }

        isValid = F.isQueueValid(move);
        assertTrue(isValid, "Queue should be valid now");

        console.log("----- Submitted Signatures");
    }

    function testExecutesSignatureQueue() public {
        bytes32 move = testSubmitsSignatures();
        SignatureQueue memory SQ = F.getSigQueue(move);

        assertTrue(T1.balanceOf(receiver) == 0, "has balance exp 0");

        uint256 snapNoBalance = vm.snapshot();
        vm.expectRevert();
        F.executeQueue(move);
        assertFalse(T1.balanceOf(receiver) == 0.1 ether, "it should not have balance");

        vm.revertTo(snapNoBalance);

        vm.startPrank(A1);
        assertTrue(SQ.Action.exeAccount != address(0), "no assoc. exe proxy");
        F20.transfer(SQ.Action.exeAccount, F20.balanceOf(A1));
        F.executeQueue(move);
        assertTrue(F20.balanceOf(receiver) == 0.1 ether, "has expected balance");

        SQ = F.getSigQueue(move);
        assertTrue(SQ.state == SQState.Executed, "expected executed");
    }

    function testGetLatentMovements() public {
        bytes32 move = testSubmitsSignatures();
        SignatureQueue memory SQ = F.getSigQueue(move);

        assertTrue(SQ.Sigs.length > 0, "expected signatures");

        address executingAccount = SQ.Action.exeAccount;
        uint256 viaNode = SQ.Action.viaNode;
        LatentMovement[] memory movements = IExecution(E).getLatentMovements(viaNode);

        assertTrue(movements.length == 1, "expected movements");
        assertTrue(movements[0].movement.category == MovementType.EnergeticMajority, "expected type 1");
        assertTrue(movements[0].movement.exeAccount == executingAccount, "expected exe account");
        assertTrue(viaNode > 0, "expected populated");

        assertTrue(movements[0].signatureQueue.state == SQState.Initialized, "expected initialized");
        vm.startPrank(A1);
        F20.transfer(SQ.Action.exeAccount, F20.balanceOf(A1));
        vm.stopPrank();
        F.executeQueue(move);
        movements = IExecution(E).getLatentMovements(viaNode);
        assertTrue(movements[0].signatureQueue.state == SQState.Executed, "expected executed");

        IExecution(E).removeLatentAction(move, 0);
        movements = IExecution(E).getLatentMovements(viaNode);
        assertTrue(movements[0].signatureQueue.state == SQState.None, "expected initialized");
        assertTrue(movements[0].movement.viaNode == 0, "expected deleted");
    }
}
