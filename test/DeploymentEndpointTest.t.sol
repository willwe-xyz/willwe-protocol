// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import {Fun} from "../src/Fun.sol";
import {Execution} from "../src/Execution.sol";
import {SignatureQueue, SQState, MovementType} from "../src/interfaces/IExecution.sol";
import {IPowerProxy} from "../src/interfaces/IPowerProxy.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IExecution, Movement, Call} from "../src/interfaces/IExecution.sol";
import {InitTest} from "./Init.t.sol";
import {TokenPrep} from "./mock/Tokens.sol";

contract WillBaseEndpointTest is Test, TokenPrep, InitTest {
    IERC20 testToken;
    uint256 rootBranchID;
    address receiver;
    address ExeEndpointAddress;

    function setUp() public override {
        vm.warp(1729286400);
        vm.roll(1729286400);
        super.setUp();

        // Prepare test token
        vm.prank(address(1));
        testToken = IERC20(makeReturnERC20());
        vm.label(address(testToken), "TestToken");

        // Transfer tokens to initial members
        vm.startPrank(address(1));
        testToken.transfer(A1, 10 ether);
        testToken.transfer(A2, 10 ether);
        testToken.transfer(A3, 10 ether);
        vm.stopPrank();

        // Create root branch
        vm.startPrank(A1);
        rootBranchID = F.spawnRootBranch(address(testToken));
        vm.stopPrank();

        uint256 parentOfEndpoint = F.getParentOf(F.toID(ExeEndpointAddress));

        // Add additional members
        vm.prank(A2);
        F.mintMembership(rootBranchID);

        vm.prank(A3);
        F.mintMembership(rootBranchID);

        deal(A1, 6 ether);
        deal(A2, 6 ether);
        deal(A3, 6 ether);

        // Mint tokens for members
        vm.startPrank(A1);
        testToken.approve(address(F), 1 ether);
        F.mint(rootBranchID, 1 ether);
        F20.mintFromETH{value: 5 ether}();

        vm.stopPrank();

        vm.startPrank(A2);
        testToken.approve(address(F), 1 ether);
        F.mint(rootBranchID, 1 ether);
        F20.mintFromETH{value: 5 ether}();
        vm.stopPrank();

        vm.startPrank(A3);
        testToken.approve(address(F), 1 ether);
        F.mint(rootBranchID, 1 ether);
        vm.stopPrank();

        // Set up receiver
        receiver = address(bytes20(type(uint160).max / 2));
    }

    function _getCallData() internal returns (bytes memory) {
        Call memory S;
        S.target = address(F20);
        bytes memory data = abi.encodeWithSelector(IERC20.transfer.selector, receiver, 0.1 ether);
        S.callData = data;
        S.value = 0;

        Call[] memory calls = new Call[](1);
        calls[0] = S;
        return abi.encodeWithSelector(IPowerProxy.tryAggregate.selector, true, calls);
    }

    function testWillBaseEndpointUsability() public {
        address endpoint = WillBaseEndpoint;

        uint256[] memory firstChildren = F.getChildrenOf(F.toID(address(F.Will())));
        uint256[] memory children = F.getChildrenOf(firstChildren[0]);

        uint256 parentOfEndpoint = F.getParentOf(F.toID(endpoint));

        bytes32 description = keccak256("Test movement description");
        bytes memory data = _getCallData();

        vm.startPrank(A1);

        F.mintMembership(parentOfEndpoint);

        bytes32 moveHash = F.startMovement(
            2, // Energetic Majority
            parentOfEndpoint,
            12,
            endpoint,
            description,
            data
        );

        // Verify movement was created correctly
        SignatureQueue memory SQ = F.getSigQueue(moveHash);

        assertTrue(SQ.state == SQState.Initialized, "Movement should be initialized");
        assertTrue(SQ.Action.exeAccount == endpoint, "Incorrect execution account");
        assertTrue(SQ.Action.category == MovementType.EnergeticMajority, "Incorrect movement type");

        // Submit signatures
        address[] memory signers = new address[](2);
        bytes[] memory signatures = new bytes[](2);

        signers[0] = A2;
        signers[1] = A3;

        // Sign the movement
        vm.startPrank(A2);
        console.log("A2 balance", testToken.balanceOf(A2));
        F.mintMembership(parentOfEndpoint);
        F20.approve(address(F), 2 ether);
        F20.mintFromETH{value: 1 ether}();
        F.mintPath(parentOfEndpoint, F20.balanceOf(A2) / 2);
        vm.stopPrank();

        console.log("A2 balance", testToken.balanceOf(A2));

        vm.startPrank(A3);
        F20.approve(address(F), 1 ether);
        F20.mintFromETH{value: 1 ether}();
        F.mintPath(parentOfEndpoint, F20.balanceOf(A3) / 2);
        vm.stopPrank();

        // Simulate signing (this would typically involve off-chain signing)
        signatures[0] = _signHash(A2pvk, SQ.Action);
        signatures[1] = _signHash(A3pvk, SQ.Action);

        // Submit signatures
        F.submitSignatures(moveHash, signers, signatures);

        // Verify queue becomes valid
        assertTrue(F.isQueueValid(moveHash), "Queue should be valid");
        assertTrue(F20.balanceOf(receiver) == 0, "Receiver has balance");
        // Execute the queue
        vm.startPrank(A1);
        F20.approve(SQ.Action.exeAccount, F20.balanceOf(A1));
        F20.transfer(SQ.Action.exeAccount, F20.balanceOf(A1));
        F.executeQueue(moveHash);

        // Verify execution
        assertTrue(F20.balanceOf(receiver) == 0.1 ether, "Transfer should be executed");
        assertTrue(F.getSigQueue(moveHash).state == SQState.Executed, "Movement should be executed");

        assertTrue(F20.balanceOf(receiver) > 0, "Receiver was not givern a balance");
    }

    function _signHash(uint256 signerPVK_, Movement memory movement) internal view returns (bytes memory) {
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
        return abi.encodePacked(r, s, v);
    }
}
