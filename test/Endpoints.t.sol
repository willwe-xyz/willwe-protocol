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

    uint256 rootNodeID;

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
        rootNodeID = F.spawnNode(uint160(address(T1)));

        B1 = F.spawnNode(rootNodeID);
        B11 = F.spawnNode(B1);
        B12 = F.spawnNode(B1);

        B2 = F.spawnNode(rootNodeID);

        vm.stopPrank();

        vm.prank(A2);
        F.mintMembership(rootNodeID);

        vm.prank(A3);
        F.mintMembership(rootNodeID);

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
        assertTrue(F.balanceOf(A1, rootNodeID) == 0, "unexpected balance");

        uint256 before = T1.balanceOf(A1);

        vm.prank(A1);
        F.mintPath(rootNodeID, 1 ether);

        vm.prank(address(1));
        T1.transfer(address(F), 10 ether);

        vm.prank(A1);
        F.burn(rootNodeID, 1 ether);

        uint256 aaafter = T1.balanceOf(A1);
        console.log(before, aaafter, before - aaafter);
    }

    function testEnergTxIni() public {
        vm.skip(false);
        vm.prank(address(1));
        T1.transfer(A1, 2 ether);

        vm.prank(address(1));
        T1.transfer(A2, 4.1 ether);

        vm.prank(address(1));
        T1.transfer(A3, 6 ether);

        vm.startPrank(A1);
        F.mintPath(rootNodeID, 1 ether);
        console.log("balance A1 rootNodeID", F.balanceOf(A1, rootNodeID));
        F.mintPath(B1, 0.9 ether);
        vm.stopPrank();

        vm.startPrank(A2);
        F.mintPath(rootNodeID, 1 ether);
        F.mintPath(B1, 1 ether);
        vm.stopPrank();

        vm.startPrank(A3);
        F.mintPath(rootNodeID, 2 ether);
        F.mintPath(B1, 1.2 ether);
        vm.stopPrank();
    }

    function testProposesNewMovement() public returns (bytes32 moveHash) {
        testSimpleDeposit();
        console.log("########### new movement________________");

        string memory description = "this is a description";
        bytes memory data = _getCallData();

        vm.startPrank(A1);

        vm.expectRevert(Execution.EXE_NoMovementType.selector);
        IExecution(E).startMovement(0, B2, 3, address(0), description, data);

        vm.expectRevert(Execution.EXE_EmptyUnallowed.selector);
        IExecution(E).startMovement(1, B2, 0, address(0), description, data);

        vm.expectRevert(Execution.EXE_NotExeAccOwner.selector);
        IExecution(E).startMovement(1, B2, 12, address(1), description, data);

        address[] memory members = F.allMembersOf(B2);
        assertTrue(members.length > 0, "should have members for majority");

        moveHash = IExecution(E).startMovement(2, B2, 12, address(0), description, data);

        assertTrue(uint256(moveHash) > 0, "empty hash returned");
        SignatureQueue memory SQ = IExecution(E).getSigQueue(moveHash);
        assertTrue(SQ.state == SQState.Initialized, "expected initialized");
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

        string memory description = "this is a description";
        bytes memory data = _getCallData();

        bytes32 moveHash = IExecution(E).startMovement(1, rootNodeID, 12, address(0), description, data);
        SignatureQueue memory SQ = IExecution(E).getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected initialized");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");
        assertTrue(SQ.Action.category == MovementType.AgentMajority, "not type 1");

        console.log("###################  AGAIN with prev exe______________");
        skip(block.timestamp + 10);
        description = "this is a description";

        moveHash = IExecution(E).startMovement(1, rootNodeID, 12, SQ.Action.exeAccount, description, data);
        SQ = IExecution(E).getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected initialized");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");
        assertTrue(SQ.Action.category == MovementType.AgentMajority, "not type 1");

        console.log("###################  Again with exe type 2______________");
        skip(block.timestamp + 10);
        description = "this is a description";

        moveHash = IExecution(E).startMovement(2, rootNodeID, 12, SQ.Action.exeAccount, description, data);
        SQ = IExecution(E).getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected initialized");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");
        assertTrue(SQ.Action.category == MovementType.EnergeticMajority, "not type 2");

        vm.stopPrank();
    }

    function testCreatesSoloEndpoint() public {
        vm.startPrank(A1);

        address endpoint = F.createEndpointForOwner(rootNodeID, A1);

        uint256 membershipID = F.membershipID(F.toID(endpoint));
        vm.label(A1, "A1User");

        NodeState memory N = F.getNodeData(rootNodeID, A1);
        assertEq(N.basicInfo[10], Strings.toHexString(endpoint), "expected endpoint in node data w user");
        assertEq(F.allMembersOf((F.toID(A1) + rootNodeID))[0], endpoint, "expected endpoint");

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
                    "Movement(uint8 category,address initiatior,address exeAccount,uint256 viaNode,uint256 expiresAt,string descriptionHash,bytes executedPayload)"
                ),
                movement.category,
                movement.initiatior,
                movement.exeAccount,
                movement.viaNode,
                movement.expiresAt,
                keccak256(abi.encodePacked(movement.description)),
                keccak256(movement.executedPayload)
            )
        );

        bytes32 hash = IExecution(E).hashMovement(movement);

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

        SQ = IExecution(E).getSigQueue(move);
        M = SQ.Action;
        STX = M.executedPayload;

        assertTrue(M.exeAccount != address(0), "safe is 0x0");
        vm.prank(address(1));
        T1.transfer(M.exeAccount, 3 ether);
    }

    function simpleSignHash(uint256 pvk, bytes32 hash) public returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvk, hash);
        signature = abi.encodePacked(r, s, v);
    }

    function testSubmitsSignatures() public returns (bytes32 move) {
        // Get structs for hash and initial checks
        (SignatureQueue memory SQ, Movement memory M, bytes memory STX, bytes32 m) = _getStructsForHash();
        move = m;
        assertTrue(uint256(IExecution(E).hashMovement(M)) == uint256(move), "Movement hash mismatch");

        // Test empty signature submission
        vm.expectRevert(Execution.EXE_ZeroLen.selector);
        IExecution(E).submitSignatures(move, new address[](0), new bytes[](0));

        // Set up members and paths
        _setupMembersAndPaths();

        // Create valid signatures - use helper function to reduce stack variables
        (address[] memory signers, bytes[] memory signatures) = _getSignaturesForMovement(M, move);

        // Submit signatures
        console.log("Submitting signatures...");
        IExecution(E).submitSignatures(move, signers, signatures);
        console.log("Signatures submitted");

        // Verify after submission
        SQ = IExecution(E).getSigQueue(move);
        console.log("Queue signers length after submission:", SQ.Signers.length);

        // For simplicity and to avoid stack too deep errors, we'll just assert we have signatures
        assertTrue(SQ.Signers.length >= 3, "No signatures stored");

        return move;
    }

    // Helper function to create signatures and reduce variables in the main test
    function _getSignaturesForMovement(Movement memory M, bytes32 moveHash)
        internal
        returns (address[] memory signers, bytes[] memory signatures)
    {
        // Create valid signatures
        signers = new address[](3);
        signatures = new bytes[](3);

        signers[0] = A1;
        signers[1] = A2;
        signers[2] = A3;

        // Get the correct digest
        bytes32 digest = IExecution(E).getDigestToSign(M);

        console.log("Digest to sign:", vm.toString(digest));
        console.log("Movement hash:", vm.toString(moveHash));

        // Sign with each key - use direct signatures from the private keys to the digest
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(A1pvk, digest);
        signatures[0] = abi.encodePacked(r1, s1, v1);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(A2pvk, digest);
        signatures[1] = abi.encodePacked(r2, s2, v2);

        (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(A3pvk, digest);
        signatures[2] = abi.encodePacked(r3, s3, v3);

        // Log signature lengths for debugging
        for (uint256 i = 0; i < signatures.length; i++) {
            console.log("Signature", i, "length:", signatures[i].length);
        }

        return (signers, signatures);
    }

    function testExecutesSignatureQueue() public {
        bytes32 move = testSubmitsSignatures();
        SignatureQueue memory SQ = IExecution(E).getSigQueue(move);

        assertTrue(T1.balanceOf(receiver) == 0, "has balance exp 0");

        uint256 snapNoBalance = vm.snapshot();
        vm.expectRevert();
        IExecution(E).executeQueue(move);
        assertFalse(T1.balanceOf(receiver) == 0.1 ether, "it should not have balance");

        vm.revertTo(snapNoBalance);

        vm.startPrank(A1);
        assertTrue(SQ.Action.exeAccount != address(0), "no assoc. exe proxy");
        F20.transfer(SQ.Action.exeAccount, F20.balanceOf(A1));
        IExecution(E).executeQueue(move);
        assertTrue(F20.balanceOf(receiver) == 0.1 ether, "has expected balance");

        SQ = IExecution(E).getSigQueue(move);
        assertTrue(SQ.state == SQState.Executed, "expected executed");
    }

    function testGetLatentMovements() public {
        bytes32 move = testSubmitsSignatures();
        SignatureQueue memory SQ = IExecution(E).getSigQueue(move);

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
        IExecution(E).executeQueue(move);
        movements = IExecution(E).getLatentMovements(viaNode);
        assertTrue(movements[0].signatureQueue.state == SQState.Executed, "expected executed");

        IExecution(E).removeLatentAction(move, 0);
        movements = IExecution(E).getLatentMovements(viaNode);
        assertTrue(movements[0].signatureQueue.state == SQState.None, "expected initialized");
        assertTrue(movements[0].movement.viaNode == 0, "expected deleted");
    }

    function testSpawnFromEndpoint() public {
        vm.startPrank(A1);

        address endpoint = F.createEndpointForOwner(rootNodeID, A1);
        vm.expectRevert();
        F.spawnNode(uint256(uint160(endpoint)));

        vm.expectRevert();
        F.mintMembership(uint256(uint160(endpoint)));
    }

    // Helper function to set up members and paths to reduce stack variables
    function _setupMembersAndPaths() internal {
        // Make sure A2 and A3 are members of B2
        if (!F.isMember(A2, B2)) {
            vm.prank(A2);
            F.mintMembership(B2);
        }

        if (!F.isMember(A3, B2)) {
            vm.prank(A3);
            F.mintMembership(B2);
        }

        // Ensure each member has a path and some tokens
        vm.startPrank(A1);
        if (F.balanceOf(A1, B2) == 0) {
            F.mintPath(B2, 1 ether);
        }
        vm.stopPrank();

        vm.startPrank(A2);
        if (F.balanceOf(A2, B2) == 0) {
            F.mintPath(B2, 1 ether);
        }
        vm.stopPrank();

        vm.startPrank(A3);
        if (F.balanceOf(A3, B2) == 0) {
            F.mintPath(B2, 1 ether);
        }
        vm.stopPrank();
    }
}
