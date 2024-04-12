// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC20ASG.sol";
import "./utils/Stage.sol";

contract GMinitTest is Test, Stage {
    IERC20ASG iGM;
    IERC20ASG defaultASG;
    /// 1 gwei initial price / 1 gwei price increase per second

    function setUp() public {
        defaultASG = IERC20ASG(InitDefaultInstance());
    }

    function testIsInit() public {
        address[] memory beneficiaries = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        beneficiaries[0] = address(1337);
        amounts[0] = 100 ether;
        address instance =
            address(new ERC20ASG("ERC20 Algo Stable Price Linear Up Only Coin", "ASG", 3,1, beneficiaries, amounts));
        iGM = IERC20ASG(instance);
        assertTrue(address(iGM).code.length > 0, "codesize is 0");
    }

    function testInitPrice(uint256 p_) public {
        vm.assume(p_ < 1000 gwei);
        address[] memory beneficiaries = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        beneficiaries[0] = address(1337);
        amounts[0] = 100 ether;
        address instance =
            address(new ERC20ASG("ERC20 Algo Stable Price Linear Up Only Coin", "ASG", p_ ,1, beneficiaries, amounts));
        iGM = IERC20ASG(instance);

        assertTrue(address(iGM).code.length > 0, "codesize is 0");
    }

    function testDefaultPrice() public {
        assertTrue(defaultASG.mintCost(1) == 1 gwei, "not 1 = 1, for t0");
        assertTrue(defaultASG.mintCost(2) == 2 gwei, "not 2 = 2, for t0");
        vm.warp(block.timestamp + 1);
        assertTrue(defaultASG.mintCost(1) == 2 gwei, "not 2, for t+1");

        assertTrue(defaultASG.currentPrice() == 2 gwei);
        assertTrue(defaultASG.burnReturns(1) == 0);

        deal(address(99), 200 gwei);

        vm.prank(address(99));
        vm.expectRevert();
        defaultASG.mint(100);
        vm.prank(address(99));
        defaultASG.mint{value: 200 gwei}(100);

        assertTrue(defaultASG.balanceOf(address(99)) == 100);

        vm.warp(block.timestamp + 99);
        assertTrue(defaultASG.currentPrice() == 101 gwei);
        assertTrue(defaultASG.totalSupply() == 100);
        assertTrue(address(defaultASG).balance == 200 gwei);
        console.log(defaultASG.burnReturns(1));
        assertTrue(defaultASG.burnReturns(1) == 2 gwei);

        uint256 b1 = address(99).balance;
        uint256 a1 = address(defaultASG).balance;
        vm.prank(address(99));
        defaultASG.burn(100);

        assertTrue(address(99).balance - b1 == a1 - address(defaultASG).balance, "simple burn balance");
    }
}
