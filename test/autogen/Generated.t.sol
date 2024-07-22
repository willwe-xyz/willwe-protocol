// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/// @dev tried to generate some tests with Claude. Did not go to well. Leaving it for future reference.

// import "forge-std/Test.sol";
// import "../../src/Fun.sol";
// import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
// import {TokenPrep} from "../mock/Tokens.sol";
// import {InitTest} from "../Init.t.sol";
// import {IMembrane} from "../../src/interfaces/IMembrane.sol";

// contract SignalTests is Test, TokenPrep, InitTest {
//     IERC20 T20;
//     uint256 rootBranchID;
//     uint256 B1;
//     uint256 B2;
//     uint256 B3;

//     function setUp() public override {
//         super.setUp();
//         vm.prank(A1);
//         T20 = IERC20(makeReturnERC20());
//         vm.label(address(T20), "T20");

//         vm.prank(A1);
//         rootBranchID = F.spawnRootBranch(address(T20));

//         vm.prank(A1);
//         B1 = F.spawnBranch(rootBranchID);

//         vm.prank(A1);
//         B2 = F.spawnBranch(rootBranchID);

//         vm.prank(A1);
//         T20.approve(address(F), type(uint256).max);

//         vm.prank(A1);
//         F.mint(rootBranchID, 10 ether);

//         vm.prank(A1);
//         F.mint(B1, 5 ether);
//     }

//     function testSendSignalBasic() public {
//         uint256[] memory signals = new uint256[](2);
//         signals[0] = 0; // No membrane change
//         signals[1] = 1 ether; // Set inflation to 1 ether

//         vm.prank(A1);
//         F.sendSignal(B1, signals);

//         assertEq(F.inflationOf(B1), 1 ether * 1 gwei, "Inflation should be set to 1 ether");
//     }

//     function testSendSignalInsufficientBalance() public {
//         uint256[] memory signals = new uint256[](2);
//         signals[0] = 0;
//         signals[1] = 1 ether;

//         vm.prank(A2);
//         vm.expectRevert(Fun.Noise.selector);
//         F.sendSignal(B1, signals);
//     }

//     function testSendSignalReentrancy() public {
//         // Deploy a malicious contract that attempts reentrancy
//         MaliciousSignaler malicious = new MaliciousSignaler(address(F));

//         // Fund the malicious contract
//         vm.prank(A1);
//         F.mint(B1, 1 ether);
//         vm.prank(A1);
//         F.safeTransferFrom(A1, address(malicious), B1, 1 ether, "");

//         // Attempt reentrancy attack
//         vm.prank(address(malicious));
//         vm.expectRevert(); // Expect the transaction to revert due to reentrancy protection
//         malicious.attack(B1);
//     }

//     function testSendSignalValueExtraction() public {
//         uint256 initialBalance = F.balanceOf(A1, B1);

//         uint256[] memory signals = new uint256[](2);
//         signals[0] = 0;
//         signals[1] = 1 ether;

//         for (uint i = 0; i < 10; i++) {
//             vm.prank(A1);
//             F.sendSignal(B1, signals);
//         }

//         uint256 finalBalance = F.balanceOf(A1, B1);
//         assertLe(finalBalance, initialBalance, "Balance should not increase from sending signals");
//     }

//     function testSendSignalEdgeCases() public {
//         uint256[] memory signals = new uint256[](2);

//         // Test with maximum possible inflation
//         signals[0] = 0;
//         signals[1] = type(uint256).max;

//         vm.prank(A1);
//         F.sendSignal(B1, signals);

//         assertEq(F.inflationOf(B1), type(uint256).max * 1 gwei, "Inflation should be set to max");

//         // Test with zero inflation
//         signals[1] = 0;

//         vm.prank(A1);
//         F.sendSignal(B1, signals);

//         assertEq(F.inflationOf(B1), 0, "Inflation should be set to 0");
//     }

//     function testRedistribute() public {
//         // Setup: Create a child branch and mint some tokens
//         vm.prank(A1);
//         B3 = F.spawnBranch(B1);

//         vm.prank(A1);
//         F.mint(B3, 1 ether);

//         // Set inflation for parent branch
//         uint256[] memory signals = new uint256[](2);
//         signals[0] = 0;
//         signals[1] = 1 ether;

//         vm.prank(A1);
//         F.sendSignal(B1, signals);

//         // Wait for some time to accrue inflation
//         vm.warp(block.timestamp + 1 days);

//         // Redistribute
//         uint256 distributedAmount = F.redistribute(B3);

//         assertTrue(distributedAmount > 0, "Should have distributed some amount");
//         assertGt(F.balanceOf(address(uint160(B3)), B1), 0, "B3 should have received some B1 tokens");
//     }

//     function testSpawnBranch() public {
//         uint256 newBranch = F.spawnBranch(rootBranchID);
//         assertTrue(newBranch != 0, "New branch should be created");
//         assertEq(F.getParentOf(newBranch), rootBranchID, "Parent should be rootBranchID");
//     }

//     function testSpawnBranchWithMembrane() public {
//         // Create a new membrane
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(T20);
//         uint256[] memory balances = new uint256[](1);
//         balances[0] = 1 ether;

//         uint256 membraneId = M.createMembrane(tokens, balances, "Test Membrane");

//         uint256 newBranch = F.spawnBranchWithMembrane(rootBranchID, membraneId);
//         assertTrue(newBranch != 0, "New branch should be created");
//         assertEq(F.getMembraneOf(newBranch), membraneId, "Membrane should be set");
//     }

//     function testMintMembership() public {
//         // Setup: Create a branch with a membrane
//         address[] memory tokens = new address[](1);
//         tokens[0] = address(T20);
//         uint256[] memory balances = new uint256[](1);
//         balances[0] = 1 ether;

//         uint256 membraneId = M.createMembrane(tokens, balances, "Test Membrane");
//         uint256 branchWithMembrane = F.spawnBranchWithMembrane(rootBranchID, membraneId);

//         // Ensure A2 has enough T20 tokens
//         vm.prank(address(1));
//         T20.transfer(A2, 2 ether);

//         vm.startPrank(A2);
//         T20.approve(address(F), 2 ether);
//         F.mintMembership(branchWithMembrane);
//         vm.stopPrank();

//         assertTrue(F.isMember(A2, branchWithMembrane), "A2 should be a member");
//     }

//     function testStartMovement() public {
//         bytes32 descriptionHash = keccak256("Test Movement");
//         bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", A2, 1 ether);

//         vm.prank(A1);
//         bytes32 movementHash = F.startMovement(1, B1, 1, address(0), descriptionHash, data);

//         assertTrue(movementHash != bytes32(0), "Movement should be created");
//     }

//     function testExecuteQueue() public {
//         // Setup: Start a movement
//         bytes32 descriptionHash = keccak256("Test Movement");
//         bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", A2, 1 ether);

//         vm.prank(A1);
//         bytes32 movementHash = F.startMovement(1, B1, 1, address(0), descriptionHash, data);

//         // Submit signatures (assuming A1 has enough voting power)
//         address[] memory signers = new address[](1);
//         signers[0] = A1;
//         bytes[] memory signatures = new bytes[](1);
//         signatures[0] = abi.encodePacked(uint8(27), bytes32(0), bytes32(0)); // Dummy signature

//         vm.prank(A1);
//         F.submitSignatures(movementHash, signers, signatures);

//         // Execute the queue
//         vm.prank(A1);
//         bool executed = F.executeQueue(movementHash);

//         assertTrue(executed, "Queue should be executed");
//     }

//     function testSubmitSignaturesGenerated() public {
//         // Setup: Start a movement
//         bytes32 descriptionHash = keccak256("Test Movement");
//         bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", A2, 1 ether);

//         vm.prank(A1);
//         bytes32 movementHash = F.startMovement(1, B1, 1, address(0), descriptionHash, data);

//         // Submit signatures
//         address[] memory signers = new address[](2);
//         signers[0] = A1;
//         signers[1] = A2;
//         bytes[] memory signatures = new bytes[](2);
//         signatures[0] = abi.encodePacked(uint8(27), bytes32(0), bytes32("0")); // Dummy signature
//         signatures[1] = abi.encodePacked(uint8(27), bytes32(0), bytes32("1")); // Another dummy signature

//         vm.prank(A1);
//         F.submitSignatures(movementHash, signers, signatures);

//         // Check if signatures were submitted
//         assertTrue(F.isQueueValid(movementHash), "Queue should be valid after submitting signatures");
//     }
// }

// contract MaliciousSignaler {
//     Fun private fun;
//     bool private attacking;

//     constructor(address _fun) {
//         fun = Fun(_fun);
//     }

//     function attack(uint256 nodeId) external {
//         require(!attacking, "Reentrancy guard");
//         attacking = true;

//         uint256[] memory signals = new uint256[](2);
//         signals[0] = 0;
//         signals[1] = 1 ether;

//         fun.sendSignal(nodeId, signals);

//         attacking = false;
//     }

//     function onERC1155Received(
//         address,
//         address,
//         uint256,
//         uint256,
//         bytes memory
//     ) external returns (bytes4) {
//         if (attacking) {
//             uint256[] memory signals = new uint256[](2);
//             signals[0] = 0;
//             signals[1] = 1 ether;
//             fun.sendSignal(1, signals); // Attempt reentrancy
//         }
//         return this.onERC1155Received.selector;
//     }
// }