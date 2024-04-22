// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {Fun} from "../src/Fun.sol";
import {Execution} from "../src/Execution.sol";
import {SignatureQueue} from "../src/interfaces/IExecution.sol";
import {TokenPrep} from "./mock/Tokens.sol";

import {SignatureQueue, SQState, MovementType} from "../src/interfaces/IExecution.sol";
import {Movement, SafeTx} from "../src/interfaces/IFun.sol";
import {ISafe} from "../src/interfaces/ISafe.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {RVT} from "../src/RVT.sol";
import {InitTest} from "./Init.t.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

contract Endpoints is Test, TokenPrep, InitTest {
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

    function setUp() public override {
        super.setUp();

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
        F.mintMembership(rootBranchID, A2);

        vm.prank(A3);
        F.mintMembership(rootBranchID, A3);

        receiver = address(bytes20(type(uint160).max / 2));
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

    function testEnergTxIni() public {
        vm.skip(false);
        /// nothing tested
        vm.prank(address(1));
        T1.transfer(A1, 1 ether);

        vm.prank(address(1));
        T1.transfer(A2, 2.1 ether);

        vm.prank(address(1));
        T1.transfer(A3, 3 ether);

        /// ##########

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

        /// ############
    }

    function testProposesNewMovement() public returns (bytes32 moveHash) {
        // if (block.chainid != 59140) return moveHash;
        if (block.chainid == 31337) vm.skip(true);
        testSimpleDeposit();
        console.log("########### new movement________________");

        bytes32 description = keccak256("this is a description");
        SafeTx memory data = _getSafeTxData();

        vm.startPrank(A1);

        vm.expectRevert(Execution.EmptyUnallowed.selector);
        F.proposeMovement(0, rootBranchID, 12, address(0), description, data);

        vm.expectRevert(Execution.NotExeAccOwner.selector);
        F.proposeMovement(1, rootBranchID, 12, address(1), description, data);

        address[] memory members = F.allMembersOf(rootBranchID);
        assertTrue(members.length > 0, "shoudl have members for majority");

        moveHash = F.proposeMovement(2, rootBranchID, 12, address(0), description, data);
        assertTrue(uint256(moveHash) > 0, "empty hash returned");
        SignatureQueue memory SQ = F.getSigQueue(moveHash);
        assertTrue(SQ.state == SQState.Initialized, "expected intiailized");
        assertTrue(SQ.Action.descriptionHash == description, "description mism");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");
        assertTrue(SQ.Action.category == MovementType.EnergeticMajority, "not type 2");

        address safe = SQ.Action.exeAccount;

        ISafe Safe = ISafe(safe);
        address[] memory ooo = Safe.getOwners();
        uint256 threshold = Safe.getThreshold();

        assertTrue(ooo.length == 1, "more than one owner for energetic type");
        assertTrue(ooo[0] == address(F.executionAddress()), "owner not ExeEngine");
        assertTrue(threshold == 1, "not 1 threshold");
        vm.stopPrank();
        return moveHash;
    }

    function _getSafeTxData() public returns (SafeTx memory S) {
        S.to = address(T1);
        S.data = abi.encodeWithSelector(IERC20.transfer.selector, receiver, 0.1 ether); //0xa9059cbb000000
        S.operation = 0;
    }

    function testCreatesNodeEndpoint() public {
        if (block.chainid != 59140) return;

        testSimpleDeposit();
        console.log("########### new ENDPOINT________________");
        vm.startPrank(A1);

        bytes32 description = keccak256("this is a description");
        SafeTx memory data = _getSafeTxData();

        bytes32 moveHash = F.proposeMovement(1, rootBranchID, 12, address(0), description, data);
        SignatureQueue memory SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected intiailized");
        assertTrue(SQ.Action.descriptionHash == description, "description mism");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");

        assertTrue(SQ.Action.category == MovementType.AgentMajority, "not type 1");

        console.log("###################  AGAIN with prev exe______________");
        skip(block.timestamp + 10);
        description = keccak256("this is a description");

        moveHash = F.proposeMovement(1, rootBranchID, 12, SQ.Action.exeAccount, description, data);
        SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "expected intiailized");
        assertTrue(SQ.Action.descriptionHash == description, "description mism");
        assertTrue(SQ.Action.exeAccount != address(0), "no exe account");

        assertTrue(SQ.Action.category == MovementType.AgentMajority, "not type 1");

        console.log("###################  Again with exe type 2______________");
        skip(block.timestamp + 10);
        description = keccak256("this is a description");

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

    function _signHash(uint256 signerPVK_, bytes32 hashToSign) public returns (bytes memory signature) {
        hashToSign = ECDSA.toEthSignedMessageHash(hashToSign);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPVK_, hashToSign);
        signature = abi.encodePacked(r, s, v);
    }

    function _getStructsForHash()
        public
        returns (SignatureQueue memory SQ, Movement memory M, SafeTx memory STX, bytes32 move)
    {
        move = testProposesNewMovement();
        console.log(vm.toString(move));
        assertTrue(uint256(move) > 0, "no hash");

        SQ = F.getSigQueue(move);
        M = SQ.Action;
        STX = M.txData;

        assertTrue(M.exeAccount != address(0), "safe is 0x0");
        vm.prank(address(1));
        T1.transfer(M.exeAccount, 3 ether);
    }

    function testSubmitsSignatures() public returns (bytes32 move) {
        (SignatureQueue memory SQ, Movement memory M, SafeTx memory STX, bytes32 move_) = _getStructsForHash();
        move = move_;
        assertTrue(uint256(keccak256(abi.encode(M))) == uint256(move));

        bytes[] memory signatures;
        address[] memory signers;

        //// submit empty signatures (0)
        vm.expectRevert(Execution.EXEC_ZeroLen.selector);
        F.submitSignatures(move, signers, signatures);

        signers = new address[](3);
        signatures = new bytes[](3);

        //// submit empty signatures (0)
        vm.expectRevert(Execution.EXEC_A0sig.selector);
        F.submitSignatures(move, signers, signatures);

        bytes memory sigA1 = _signHash(A1pvk, move);
        bytes memory sigA2 = _signHash(A2pvk, move);
        bytes memory sigA3 = _signHash(A3pvk, move);

        signers[0] = A1;
        signers[1] = A2;
        signers[2] = A3;
        signatures[0] = sigA1;
        signatures[1] = sigA2;
        signatures[2] = sigA3;

        snapSig1 = vm.snapshot();
        //// submit empty signatures (0)
        F.submitSignatures(move, signers, signatures);

        bytes memory sigb;

        SQ = F.getSigQueue(move);

        assertTrue(SQ.Signers.length == SQ.Sigs.length, "len mism");
        assertTrue(SQ.Signers.length == 3, "unexp sig len");

        assertTrue(SQ.Signers[0] == A2, "firs signer A2");
        assertTrue(SQ.Signers[1] == A3, "signer not A3");
        assertTrue(SQ.Signers[2] == A1, "signer not A1");

        snapSig2 = vm.snapshot();

        assertFalse(F.isValidSignature(move, sigb) == 0x1626ba7e, "sig not valid");
        assertTrue(F.isQueueValid(move), "sq not valid");

        console.log("----- Submitted Signatures");
    }

    function testExecutesSignatureQueue() public {
        bytes32 move = testSubmitsSignatures();
        SignatureQueue memory SQ = F.getSigQueue(move);

        uint256 safeNonce = ISafe(SQ.Action.exeAccount).nonce();
        assertTrue(T1.balanceOf(receiver) == 0, "has balance exp 0");

        F.executeQueue(move);

        assertTrue(T1.balanceOf(receiver) == 0.1 ether, "has expected balance");
        assertTrue(safeNonce < ISafe(SQ.Action.exeAccount).nonce(), "nonce not ++");

        SQ = F.getSigQueue(move);
        assertTrue(SQ.state == SQState.Executed, "expected executed");
    }
}
