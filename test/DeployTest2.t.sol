// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Fungido.sol";
import {TokenPrep} from "./mock/Tokens.sol";
import {Execution} from "../src/Execution.sol";
import {WillWe} from "../src/WillWe.sol";
import {IPowerProxy} from "../src/interfaces/IPowerProxy.sol";
import {InitTest} from "./Init.t.sol";
import {WillWeDeploy2} from "../script/WillWeDeploy2.s.sol";
import "forge-std/console.sol";

contract DeployTest2 is Test, TokenPrep, WillWeDeploy2 {
    IPowerProxy KiberDirector;
    address deployer;
    uint256 startBlock;

    using Strings for uint256;

    address[] users;
    uint256 constant NUM_USERS = 5;
    uint256 constant INITIAL_ETH = 10 ether;

    function setUp() public override {
        super.setUp();
        vm.warp(1738158468);
        super.run();
        vm.warp(1738168468);
        vm.roll(100);
        deployer = 0x920CbC9893bF12eD967116136653240823686D9c;
        KiberDirector = IPowerProxy(payable(WW.control(0)));
        startBlock = block.number;

        for (uint256 i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(0x1000 + i));
            users.push(user);
            vm.deal(user, INITIAL_ETH);
        }
    }

    function testContractsDeployed() public {
        assertTrue(address(WW).code.length > 1, "no code fun");
        assertTrue(address(E).code.length > 0, "no code E");
        assertTrue(address(F20).code.length > 0, "no code F20");
        assertTrue(address(KiberDirector).code.length > 0, "no code safe");
    }

    function testFoundingAgent() public {
        assertTrue(address(KiberDirector).code.length > 1, "code len of Safe 0");
        assertTrue(KiberDirector.owner() == address(E), "Exe not owner");
        assertTrue(WW.getParentOf(WW.toID(address(KiberDirector))) > 0, "no parent");
        assertTrue(WW.getParentOf(WW.getParentOf(WW.toID(address(KiberDirector)))) > 0, "no for parent of founding");
    }

    function testPriceEvolution() public {
        // Initial state verification
        vm.roll(block.number + 3);
        logState("Initial State");
        assertTrue(F20.totalSupply() == 1 ether, "Initial supply should be 1 ether");
        assertTrue(F20.currentPrice() == 1 gwei, "Initial price should be 1 gwei");

        // Mint 1 ether tokens with 1 gwei
        vm.roll(block.number + 3);
        vm.startPrank(users[0]);
        F20.mintFromETH{value: 1 gwei}();

        uint256 firstMintBalance = F20.balanceOf(users[0]);
        assertEq(firstMintBalance, 1 ether, "Should get 1 ether tokens for 1 gwei");
        logStateDetailed("After First Mint", users[0]);

        // Mint with 2 gwei - should get 1 ether tokens
        vm.roll(block.number + 3);
        uint256 price = F20.currentPrice();
        F20.mintFromETH{value: price}();
        uint256 secondMintBalance = F20.balanceOf(users[0]);
        assertEq(secondMintBalance - firstMintBalance, 1 ether, "Second mint should give 1 ether tokens");
        logStateDetailed("After Second Mint", users[0]);

        // Test burn mechanics
        uint256 burnAmount = 1 ether;
        uint256 ethBefore = users[0].balance;
        F20.burn(burnAmount);
        uint256 ethAfter = users[0].balance;
        uint256 ethReturned = ethAfter - ethBefore;
        logStateDetailed("After Burn", users[0]);

        // Large mint test
        vm.stopPrank();
        vm.startPrank(users[1]);
        vm.roll(block.number + 3);
        uint256 price2 = F20.currentPrice();

        F20.mintFromETH{value: 3 ether}();
        logState("After Large Mint");

        // Log final state with all balances
        vm.stopPrank();

        vm.roll(block.number + 3);

        vm.deal(users[1], 10 ether);
        vm.prank(users[1]);
        F20.mintFromETH{value: 9 ether}();

        vm.roll(block.number + 3);
        uint256 finalPrice = F20.currentPrice();
        assertTrue(finalPrice > price2, "Price should increase after large mint");

        logDetailedState("Final State");
    }

    function logDetailedState(string memory label) internal view {
        logState(label);
        for (uint256 i = 0; i < users.length; i++) {
            console.log(string.concat("User ", (i + 1).toString(), " Token Balance: "), F20.balanceOf(users[i]));
            console.log(string.concat("User ", (i + 1).toString(), " ETH Balance: "), users[i].balance);
        }
        console.log("Price/Supply Ratio:", F20.currentPrice() * 1e9 / F20.totalSupply());
    }

    function testWillPrice() public {
        vm.roll(block.number + 3);
        assertTrue(F20.totalSupply() > 0, "no supply");
        assertTrue(F20.currentPrice() > 0, "no price");
        assertTrue(F20.currentPrice() == 1 gwei, "price not 1 gwei");
        uint256 price0 = F20.currentPrice();
        logState("Initial State");

        // First mint and transfer
        vm.roll(block.number + 3);
        vm.startPrank(deployer);
        deal(deployer, 1 ether);
        F20.mintFromETH{value: 0.1 ether}();
        F20.transfer(address(KiberDirector), F20.balanceOf(deployer));

        vm.roll(block.number + 3);
        uint256 price1 = F20.currentPrice();
        logState("After First Mint and Transfer");

        // Second mint and transfer
        vm.roll(block.number + 3);
        F20.mintFromETH{value: F20.currentPrice()}();
        F20.transfer(address(KiberDirector), F20.balanceOf(deployer));
        vm.roll(block.number + 3);
        uint256 price2 = F20.currentPrice();
        vm.stopPrank();
        logState("After Second Mint and Transfer");

        // Verify price dynamics
        assertTrue(price1 > price0, "Price should increase after first mint");
        assertTrue(price2 > price1, "Price should increase after second mint");
    }

    function testMintBurnCycle() public {
        vm.roll(block.number + 3);
        vm.startPrank(users[0]);

        // Test minimum mint
        F20.mintFromETH{value: 1 gwei}();
        uint256 initialBalance = F20.balanceOf(users[0]);
        assertEq(initialBalance, 1 ether, "Initial mint amount incorrect");
        logStateDetailed("After Initial Mint", users[0]);

        vm.roll(block.number + 3);
        // Burn exact amount
        uint256 ethBalanceBefore = users[0].balance;
        uint256 expectedReturn = F20.burnReturns(initialBalance);
        F20.burn(initialBalance);
        uint256 ethReturned = users[0].balance - ethBalanceBefore;

        console.log(ethBalanceBefore, initialBalance, ethReturned, expectedReturn);
        assertEq(ethReturned, expectedReturn, "Burn return amount incorrect");
        logStateDetailed("After Full Burn", users[0]);

        vm.stopPrank();
    }

    function logState(string memory label) internal view {
        console.log("\n=== ", label, " ===");
        console.log("Block:", block.number);
        console.log("Total Supply:", F20.totalSupply());
        console.log("Price (gwei):", F20.currentPrice());
        console.log("Contract ETH Balance:", address(F20).balance);
        console.log("KiberDirector Balance:", F20.balanceOf(address(KiberDirector)));
    }

    function logStateDetailed(string memory label, address user) internal view {
        logState(label);
        console.log("User Token Balance:", F20.balanceOf(user));
        console.log("User ETH Balance:", user.balance);
        console.log("Token/ETH Ratio:", F20.totalSupply() / address(F20).balance);
        console.log("Contract ETH Balance:", address(F20).balance);
    }
}
