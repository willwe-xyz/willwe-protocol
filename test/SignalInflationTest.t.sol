// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {NodeState} from "../src/interfaces/IExecution.sol";
import {Fun} from "../src/Fun.sol";
import {TokenPrep} from "./mock/Tokens.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {InitTest} from "./Init.t.sol";
import "forge-std/console.sol";
import {Fungido} from "../src/Fungido.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract SignalInflationTests is InitTest, TokenPrep {
    IERC20 T1;
    uint256 rootBranchID;
    uint256 B1;
    uint256 B2;
    uint256 B11;
    uint256 B12;
    uint256 B21;
    uint256 B22;

    using Strings for uint256;

    function setUp() public virtual override {
        super.setUp();

        // Create an instance of the ERC20 token and mint sufficient supply
        T1 = IERC20(makeReturnERC20());

        // Ensure the initial supply is sufficient
        uint256 initialBalance = T1.balanceOf(address(this));
        console.log("Initial balance of test contract:", initialBalance);

        // Allocate sufficient tokens to accounts A1 and A2
        T1.transfer(A1, 1000 ether);
        T1.transfer(A2, 1000 ether);

        // Check the allocated balance
        uint256 balanceA1 = T1.balanceOf(A1);
        uint256 balanceA2 = T1.balanceOf(A2);
        console.log("Balance of A1 after transfer:", balanceA1);
        console.log("Balance of A2 after transfer:", balanceA2);

        // Ensure balances are correctly assigned
        assertEq(balanceA1, 1000 ether, "Balance of A1 is incorrect");
        assertEq(balanceA2, 1000 ether, "Balance of A2 is incorrect");

        // Approve the WillWe contract to spend tokens on behalf of A1 and A2
        vm.prank(A1);
        T1.approve(address(F), type(uint256).max);
        vm.prank(A2);
        T1.approve(address(F), type(uint256).max);

        // Create branches under the root branch
        vm.startPrank(A1); // Start with root
        rootBranchID = F.spawnRootBranch(address(T1));
        B1 = F.spawnBranch(rootBranchID);
        B2 = F.spawnBranch(rootBranchID);
        B11 = F.spawnBranch(B1);
        B12 = F.spawnBranch(B1);
        B21 = F.spawnBranch(B2);
        B22 = F.spawnBranch(B2);
        vm.stopPrank(); // End with root

        // Ensure branches are correctly created
        console.log("rootBranchID:", rootBranchID);
        console.log("B1:", B1);
        console.log("B2:", B2);
        console.log("B11:", B11);
        console.log("B12:", B12);
        console.log("B21:", B21);
        console.log("B22:", B22);
    }

    // Ensure proper funding of parent nodes
    function fundParentNode(address sender, uint256 parentID, uint256 amount) internal {
        // Mint context tokens into parent ID with sufficient external ERC20
        vm.prank(sender);
        F.mint(parentID, amount);
    }

    function testSignalInflationRateChanges() public {
        fundParentNode(A1, rootBranchID, 100 ether);
        console.log("Balance of A1 after funding rootBranchID:", T1.balanceOf(A1));

        fundParentNode(A1, B1, 100 ether);
        console.log("Balance of A1 after funding B1 with 100 ether:", T1.balanceOf(A1));
        vm.startPrank(A1);
        // Fund rootBranchID with external ERC20 balance

        // Fund B1 from rootBranchID balance

        uint256[] memory signals = new uint256[](2);
        signals[1] = 5000; // Signal 0.05% inflation
        F.sendSignal(B1, signals);
        assertEq(F.inflationOf(B1), 5000 * 1 gwei, "Incorrect inflation rate");

        vm.warp(block.timestamp + 1 days);
        signals[1] = 7000; // Signal 0.07% inflation
        F.sendSignal(B1, signals);
        assertEq(F.inflationOf(B1), 7000 * 1 gwei, "Incorrect inflation rate after update");

        console.log("Final Balance of A1:", T1.balanceOf(A1));
        vm.stopPrank();
    }

    function testMaximumSignalPercentageEnforcement() public {
        // Fund rootBranchID with external ERC20 balance
        fundParentNode(A1, rootBranchID, 100 ether);
        console.log("Balance of A1 after funding rootBranchID:", T1.balanceOf(A1));

        // Fund B1 from rootBranchID balance
        fundParentNode(A1, B1, 100 ether);
        console.log("Balance of A1 after funding B1 with 100 ether:", T1.balanceOf(A1));
        vm.startPrank(A1);

        uint256[] memory signals = new uint256[](4);
        signals[2] = 6000; // 60% to B11
        signals[3] = 5000; // exceeding 100%

        vm.expectRevert(abi.encodeWithSelector(Fungido.IncompleteSign.selector));
        F.sendSignal(B1, signals);
        console.log("Failed Signal - Balance of A1: ", T1.balanceOf(A1));

        signals[2] = 6000; // 60% to B11
        signals[3] = 4000; // 40% to B12
        F.sendSignal(B1, signals);
        console.log("Successful Signal - Balance of A1:", T1.balanceOf(A1));

        vm.warp(block.timestamp + 100);

        signals[2] = 0; // 60% to B11
        signals[3] = 10000; // 40% to B12
        F.sendSignal(B1, signals);

        //// @todo test user signal total cannot be more or less than 100% in diffrent cummulative transactions

        console.log("Final Balance of A1:", T1.balanceOf(A1));
        vm.stopPrank();
    }

    function testSignalAndRedistribution() public {
        // Fund rootBranchID with external ERC20 balance
        fundParentNode(A1, rootBranchID, 100 ether);

        // Fund B1 from rootBranchID balance
        fundParentNode(A1, B1, 100 ether);
        vm.startPrank(A1);

        uint256[] memory signals = new uint256[](4);
        signals[2] = 6000; // 60% to B11
        signals[3] = 4000; // 40% to B12
        F.sendSignal(B1, signals);

        NodeState memory node = F.getNodeData(B11, address(0));

        string memory initialEligibility = node.basicInfo[7];
        uint256 initialBalance = F.balanceOf(address(uint160(B11)), B1);

        vm.warp(block.timestamp + 7 days);
        F.redistribute(B11);

        node = F.getNodeData(B11, address(0));
        string memory postExpirationEligibility = node.basicInfo[7];

        uint256 postRedistriBalance = F.balanceOf(address(uint160(B11)), B1);

        assertEq(initialEligibility, postExpirationEligibility, "Signal expiration did not work correctly");

        // assertTrue(
        //     postRedistriBalance - initialBalance >= initialEligibility * 7 days, "incorrect redistributed amount"
        // );

        assertTrue(initialBalance < postRedistriBalance, "Nothing redistributed");
        console.log("initial post balance -- ", initialBalance, postRedistriBalance);

        console.log("Balance of A1 after signal expiration:", T1.balanceOf(A1));
        console.log("Final Balance of A1:", T1.balanceOf(A1));
        vm.stopPrank();
    }

    function testGetUserNodeSignals() public {
        // Fund rootBranchID with external ERC20 balance
        fundParentNode(A1, rootBranchID, 100 ether);

        // Fund B1 from rootBranchID balance
        fundParentNode(A1, B1, 100 ether);
        vm.startPrank(A1);

        uint256[] memory signals = new uint256[](4);
        signals[2] = 6000; // 60% to B11
        signals[3] = 4000; // 40% to B12
        F.sendSignal(B1, signals);

        uint256[2][] memory userNodeSignals = F.getUserNodeSignals(A1, B1);

        // Check if the length of the returned array is correct
        assertEq(userNodeSignals.length, 2);

        // Check if the signals and timestamps are correct
        assertEq(userNodeSignals[0][0], 6000);
        assertEq(userNodeSignals[1][0], 4000);
        assertEq(userNodeSignals[0][1], block.timestamp);
        assertEq(userNodeSignals[1][1], block.timestamp);

        vm.stopPrank();
    }

    function testGetNodeDataWithUserSignals() public {
        // Fund rootBranchID with external ERC20 balance
        fundParentNode(A1, rootBranchID, 100 ether);

        // Fund B1 from rootBranchID balance
        fundParentNode(A1, B1, 100 ether);
        vm.startPrank(A1);

        uint256[] memory signals = new uint256[](4);
        signals[2] = 6000; // 60% to B11
        signals[3] = 4000; // 40% to B12
        F.sendSignal(B1, signals);

        NodeState memory nodeData = F.getNodeData(B1, A1);

        // Check if the basic info is correct
        assertEq(nodeData.basicInfo[0], uint256(uint160(B1)).toString(), "node id issue");
        assertEq(nodeData.basicInfo[1], F.inflationOf(B1).toString(), "inflation issue");
        assertEq(nodeData.basicInfo[2], F.balanceOf(address(uint160(B1)), rootBranchID).toString(), "balance 111");
        assertEq(nodeData.basicInfo[3], F.balanceOf(address(uint160(B1)), B1).toString(), "balance 222");
        assertEq(
            nodeData.basicInfo[4], F.asRootValuation(B1, F.balanceOf(address(uint160(B1)), B1)).toString(), "root val"
        );
        assertEq(
            nodeData.basicInfo[5],
            F.asRootValuation(B1, F.balanceOf(address(uint160(B1)), rootBranchID)).toString(),
            "root val 22"
        );
        assertEq(nodeData.basicInfo[6], F.getMembraneOf(B1).toString(), "membrane issue");
        assertEq(nodeData.basicInfo[9], F.balanceOf(A1, B1).toString(), "user balance f");

        assertEq(nodeData.signals.length, 1, "signals len f");
        assertEq(nodeData.signals[0].lastRedistSignal.length, 2, "bal ne redistribution");
        assertEq(nodeData.signals[0].lastRedistSignal[0], "6000");
        assertEq(nodeData.signals[0].lastRedistSignal[1], "4000");
        assertEq(nodeData.signals[0].MembraneInflation.length, 2, "len inflation");
        assertEq(nodeData.signals[0].MembraneInflation[0][1], F.inflationOf(B1).toString(), "mi 1");
        assertEq(nodeData.signals[0].MembraneInflation[1][1], F.inflationOf(B1).toString(), "mi 1");

        vm.stopPrank();
    }
}
