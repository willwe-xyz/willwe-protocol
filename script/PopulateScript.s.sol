// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/WillWe.sol";
import "../src/Execution.sol";
import "../src/Will.sol";
import "../src/Membranes.sol";
import "../test/mock/Tokens.sol";

contract WillWeDeployScript is Script {
    WillWe public willwe;
    Execution public execution;
    Will public will;
    Membranes public membranes;
    X20RONAlias public weth;
    X20RONAlias public mkr;
    X20RONAlias public dogCoinMax;
    X20RONAlias public xVentures;

    // Specified contract addresses (checksummed and payable)
    address payable constant WILL_ADDRESS = payable(0x9d814170537951fE8eD28A534CDE9F30Fd731A64);
    address payable constant EXECUTION_ADDRESS = payable(0x96B88F2B098AE65CFD93B226F1a9444EC4043eBe);
    address payable constant MEMBRANES_ADDRESS = payable(0x214FEA19B4ef0C3d1440398ECd0A2523dCf14210);
    address payable constant WILLWE_ADDRESS = payable(0xf32F9c6004Cd998Bc0319290b348A1DbFFc4Ef67);

    // Private keys for multiple accounts
    uint256 constant ACCOUNT1_PRIVATE_KEY = 0x2345678901234567890123456789012345678901234567890123456789012345;
    uint256 constant ACCOUNT2_PRIVATE_KEY = 0x3456789012345678901234567890123456789012345678901234567890123456;

    function setUp() public {
        vm.label(vm.addr(vm.envUint("WEWILL_02")), "Deployer 0_WEWILL_2");
        vm.label(vm.addr(ACCOUNT1_PRIVATE_KEY), "Account1");
        vm.label(vm.addr(ACCOUNT2_PRIVATE_KEY), "Account2");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("WEWILL_02");
        address deployer = vm.addr(deployerPrivateKey);
        address account1 = vm.addr(ACCOUNT1_PRIVATE_KEY);
        address account2 = vm.addr(ACCOUNT2_PRIVATE_KEY);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock tokens directly
        weth = new X20RONAlias("Wrapped Ether", "WETH");
        mkr = new X20RONAlias("Maker", "MKR");
        dogCoinMax = new X20RONAlias("DogCoinMax", "DCM");
        xVentures = new X20RONAlias("XVentures", "XV");

        console.log("Deployer WETH balance:", weth.balanceOf(deployer));
        console.log("Deployer MKR balance:", mkr.balanceOf(deployer));
        console.log("Deployer DCM balance:", dogCoinMax.balanceOf(deployer));
        console.log("Deployer XV balance:", xVentures.balanceOf(deployer));

        uint256 transferAmount = 100_000 ether;
        weth.transfer(account1, transferAmount);
        mkr.transfer(account1, transferAmount);
        dogCoinMax.transfer(account1, transferAmount);
        xVentures.transfer(account1, transferAmount);

        weth.transfer(account2, transferAmount);
        mkr.transfer(account2, transferAmount);
        dogCoinMax.transfer(account2, transferAmount);
        xVentures.transfer(account2, transferAmount);

        // Initialize contract instances
        will = Will(WILL_ADDRESS);
        execution = Execution(EXECUTION_ADDRESS);
        membranes = Membranes(MEMBRANES_ADDRESS);
        willwe = WillWe(WILLWE_ADDRESS);

        // Set up initial configuration
        execution.setWillWe(WILLWE_ADDRESS);

        // Create root nodes
        uint256 rootNode1 = willwe.spawnRootBranch(address(weth));
        uint256 rootNode2 = willwe.spawnRootBranch(address(mkr));
        uint256 rootNode3 = willwe.spawnRootBranch(address(dogCoinMax));
        uint256 rootNode4 = willwe.spawnRootBranch(address(xVentures));

        // Approve tokens for deposits
        uint256 approveAmount = 500_000 ether;
        weth.approve(address(willwe), approveAmount);
        mkr.approve(address(willwe), approveAmount);
        dogCoinMax.approve(address(willwe), approveAmount);
        xVentures.approve(address(willwe), approveAmount);

        console.log("Deployer WETH balance before mintPath:", weth.balanceOf(deployer));
        console.log("Deployer MKR balance before mintPath:", mkr.balanceOf(deployer));
        console.log("Deployer DCM balance before mintPath:", dogCoinMax.balanceOf(deployer));
        console.log("Deployer XV balance before mintPath:", xVentures.balanceOf(deployer));

                // Log token addresses and names
        console.log("WETH Address:", address(weth));
        console.log("WETH Name:", weth.name());
        console.log("WETH Symbol:", weth.symbol());

        console.log("MKR Address:", address(mkr));
        console.log("MKR Name:", mkr.name());
        console.log("MKR Symbol:", mkr.symbol());

        console.log("DCM Address:", address(dogCoinMax));
        console.log("DCM Name:", dogCoinMax.name());
        console.log("DCM Symbol:", dogCoinMax.symbol());

        console.log("XV Address:", address(xVentures));
        console.log("XV Name:", xVentures.name());
        console.log("XV Symbol:", xVentures.symbol());

        console.log("Deployer WETH balance:", weth.balanceOf(deployer));
        console.log("Deployer MKR balance:", mkr.balanceOf(deployer));
        console.log("Deployer DCM balance:", dogCoinMax.balanceOf(deployer));
        console.log("Deployer XV balance:", xVentures.balanceOf(deployer));

        uint256 Node1b = willwe.spawnBranch(rootNode1);
        uint256 Node2b = willwe.spawnBranch(rootNode2);
        uint256 Node3b = willwe.spawnBranch(rootNode3);
        uint256 Node4b = willwe.spawnBranch(rootNode4);


        // uint256 Node1a = willwe.spawnBranch(Node1b);
        // uint256 Node2a = willwe.spawnBranch(Node2b);
        // uint256 Node3a = willwe.spawnBranch(Node3b);
        // uint256 Node4a = willwe.spawnBranch(Node4b);

        // MintPath operations for deployer
        // willwe.mintPath(Node1a, 10_000 ether);
        // willwe.mintPath(Node2a, 12_000 ether);
        // willwe.mintPath(Node3b, 20_000 ether);
        // willwe.mintPath(Node4b, 7_000 ether);

        vm.stopBroadcast();

        // // Account 1 operations
        // vm.startBroadcast(ACCOUNT1_PRIVATE_KEY);

        // uint256 child1_1 = willwe.spawnBranch(rootNode1);
        // uint256 child2_1 = willwe.spawnBranch(rootNode2);

        // weth.approve(address(willwe), transferAmount);
        // mkr.approve(address(willwe), transferAmount);
        // dogCoinMax.approve(address(willwe), transferAmount);
        // xVentures.approve(address(willwe), transferAmount);

        // willwe.mintPath(child1_1, 25_000 ether);
        // willwe.mintPath(child2_1, 25_000 ether);
        // willwe.mintPath(rootNode3, 25_000 ether);

        // vm.stopBroadcast();

        // // Account 2 operations
        // vm.startBroadcast(ACCOUNT2_PRIVATE_KEY);

        // // Mint membership for Account2 in the parent nodes
        // willwe.mintMembership(rootNode1);
        // willwe.mintMembership(child1_1);

        // uint256 child1_2 = willwe.spawnBranch(rootNode1);
        // uint256 grandchild1_1_1 = willwe.spawnBranch(child1_1);

        // weth.approve(address(willwe), transferAmount);
        // mkr.approve(address(willwe), transferAmount);
        // dogCoinMax.approve(address(willwe), transferAmount);
        // xVentures.approve(address(willwe), transferAmount);

        // willwe.mintPath(child1_2, 25_000 ether);
        // willwe.mintPath(grandchild1_1_1, 12_500 ether);
        // willwe.mintPath(rootNode4, 25_000 ether);

        // vm.stopBroadcast();
    }
}


//   ======== 
//   WETH Address: 0x48d85D132A40Fc7703c2801d125918d8E7811880
//   WETH Name: Wrapped Ether
//   WETH Symbol: WETH
//   MKR Address: 0xB43fa5F6D3107BCa2FcC6F38e6A073f514432cC8
//   MKR Name: Maker
//   MKR Symbol: MKR
//   DCM Address: 0x695A5F44C621Ba7a8e92B9f7bB27e7DDF25DDe0F
//   DCM Name: DogCoinMax
//   DCM Symbol: DCM
//   XV Address: 0x56Be55a2A5ED3e775aecD099a4a98FfA6f25a283
//   XV Name: XVentures
//   XV Symbol: XV