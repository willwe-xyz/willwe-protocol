// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.25;

// import "forge-std/Script.sol";
// import "../src/WillWe.sol";
// import "../src/Execution.sol";
// import "will/contracts/Will.sol";
// import "../src/Membranes.sol";
// import "../test/mock/Tokens.sol";

// import "openzeppelin-contracts/contracts/utils/Strings.sol";

// contract PopulateScript is Script {
//     using Strings for uint256;

//     WillWe public willwe;
//     Execution public execution;
//     Will public will;
//     Membranes public membranes;
//     X20RONAlias public weth;
//     X20RONAlias public mkr;
//     X20RONAlias public dogCoinMax;
//     X20RONAlias public xVentures;

//     //   ###############################
//     //   Foundation Agent Safe at:  0xF33c1682a9C68cd3982666612279aE8a2E55AbA3
//     //   Will:  0xC27A26bDF3dCA8A7e18AAE061EeE1b38183562F2
//     //   Membrane:  0x8E448f0568A47359a0077494B032eb9D588cB9d1
//     //   Execution:  0x5F7147439f991722e95296BA10B3E34b2Ea75C55
//     //   WillWe:  0x573879054B44b10a33f77f74EB70084F303bcb11
//     //   ###############################

//     // Specified contract addresses (checksummed and payable)
//     address payable constant WILL_ADDRESS = payable(0xC27A26bDF3dCA8A7e18AAE061EeE1b38183562F2);
//     address payable constant EXECUTION_ADDRESS = payable(0x5F7147439f991722e95296BA10B3E34b2Ea75C55);
//     address payable constant MEMBRANES_ADDRESS = payable(0x8E448f0568A47359a0077494B032eb9D588cB9d1);
//     address payable constant WILLWE_ADDRESS = payable(0x573879054B44b10a33f77f74EB70084F303bcb11);

//     // Private keys for multiple accounts
//     uint256 ACCOUNT1_PRIVATE_KEY = uint256(keccak256(abi.encodePacked("WeiShogun")));
//     uint256 ACCOUNT2_PRIVATE_KEY = uint256(keccak256(abi.encodePacked("TodShogun")));

//     function setUp() public {
//         vm.label(vm.addr(vm.envUint("WEWILL_02")), "Deployer 0_WEWILL_2");
//         vm.label(vm.addr(ACCOUNT1_PRIVATE_KEY), "WEWILL_USER1");
//         vm.label(vm.addr(ACCOUNT2_PRIVATE_KEY), "WEWILL_USER2");

//         console.log("WeiShogun 1 PVK : ", ACCOUNT1_PRIVATE_KEY.toHexString());
//         console.log("TodShogun 2 PVK : ", ACCOUNT2_PRIVATE_KEY.toHexString());
//     }

//     function run() public {
//         address deployer = setupAccounts();

//         deployTokens(deployer);

//         initializeContracts();

//         configureInitialSettings(deployer);

//         (uint256 rootNode1, uint256 rootNode2, uint256 rootNode3, uint256 rootNode4) = createRootNodes(deployer);

//         approveTokensForDeposits(deployer);

//         // mintPathOperations(deployer, rootNode1, rootNode2, rootNode3, rootNode4);
//     }

//     function setupAccounts() internal returns (address deployer) {
//         console.log("#####3 setupAccounts ####");
//         uint256 deployerPrivateKey = vm.envUint("WW_deployer_taiko");
//         deployer = vm.addr(deployerPrivateKey);
//         address account1 = vm.addr(ACCOUNT1_PRIVATE_KEY);
//         address account2 = vm.addr(ACCOUNT2_PRIVATE_KEY);

//         console.log("Deployer:", deployer);
//         console.log("WEWILL_USER1 - ", account1);
//         console.log("WEWILL_USER2 - ", account2);

//         vm.startBroadcast(deployerPrivateKey);

//         return deployer;
//     }

//     function deployTokens(address deployer) internal {
//         console.log("#####3 deployTokens ####");
//         weth = new X20RONAlias("Solc Dev", "ETH.SOL");
//         mkr = new X20RONAlias("Hipo Inu Coin", "HIC");
//         dogCoinMax = new X20RONAlias("Fancy Cats", "FACA");
//         xVentures = new X20RONAlias("", "XVVU");

//         console.log("Deployer WETH balance:", weth.balanceOf(deployer));
//         console.log("Deployer MKR balance:", mkr.balanceOf(deployer));
//         console.log("Deployer DCM balance:", dogCoinMax.balanceOf(deployer));
//         console.log("Deployer XV balance:", xVentures.balanceOf(deployer));

//         transferTokensToAccounts(deployer);
//     }

//     function transferTokensToAccounts(address deployer) internal {
//         console.log("#####3 transferTokensToAccounts ####");

//         uint256 transferAmount = 100_000 ether;
//         weth.transfer(vm.addr(ACCOUNT1_PRIVATE_KEY), transferAmount);
//         mkr.transfer(vm.addr(ACCOUNT1_PRIVATE_KEY), transferAmount);
//         dogCoinMax.transfer(vm.addr(ACCOUNT1_PRIVATE_KEY), transferAmount);
//         xVentures.transfer(vm.addr(ACCOUNT1_PRIVATE_KEY), transferAmount);

//         weth.transfer(vm.addr(ACCOUNT2_PRIVATE_KEY), transferAmount);
//         mkr.transfer(vm.addr(ACCOUNT2_PRIVATE_KEY), transferAmount);
//         dogCoinMax.transfer(vm.addr(ACCOUNT2_PRIVATE_KEY), transferAmount);
//         xVentures.transfer(vm.addr(ACCOUNT2_PRIVATE_KEY), transferAmount);
//     }

//     function initializeContracts() internal {
//         console.log("#####3 initializeContracts ####");

//         will = Will(WILL_ADDRESS);
//         execution = Execution(EXECUTION_ADDRESS);
//         membranes = Membranes(MEMBRANES_ADDRESS);
//         willwe = WillWe(WILLWE_ADDRESS);
//     }

//     function configureInitialSettings(address WILLWE_ADDRESS) internal {
//         execution.setWillWe(WILLWE_ADDRESS);
//     }

//     function createRootNodes(address deployer)
//         internal
//         returns (uint256 rootNode1, uint256 rootNode2, uint256 rootNode3, uint256 rootNode4)
//     {
//         console.log("#####3 createRootNodes ####");
//         rootNode1 = willwe.spawnRootBranch(address(weth));
//         rootNode2 = willwe.spawnRootBranch(address(mkr));
//         rootNode3 = willwe.spawnRootBranch(address(dogCoinMax));
//         rootNode4 = willwe.spawnRootBranch(address(xVentures));
//     }

//     function approveTokensForDeposits(address deployer) internal {
//         console.log("##### approveTokensForDeposits ####");
//         uint256 approveAmount = 500_000 ether;
//         weth.approve(address(willwe), approveAmount);
//         mkr.approve(address(willwe), approveAmount);
//         dogCoinMax.approve(address(willwe), approveAmount);
//         xVentures.approve(address(willwe), approveAmount);

//         console.log("Deployer WETH balance before mintPath:", weth.balanceOf(deployer));
//         console.log("Deployer MKR balance before mintPath:", mkr.balanceOf(deployer));
//         console.log("Deployer DCM balance before mintPath:", dogCoinMax.balanceOf(deployer));
//         console.log("Deployer XV balance before mintPath:", xVentures.balanceOf(deployer));
//     }

//     function mintPathOperations(
//         address deployer,
//         uint256 rootNode1,
//         uint256 rootNode2,
//         uint256 rootNode3,
//         uint256 rootNode4
//     ) internal {
//         console.log("##### mintPathOperations ####");

//         console.log("Deployer WETH balance:", weth.balanceOf(deployer));
//         console.log("Deployer MKR balance:", mkr.balanceOf(deployer));
//         console.log("Deployer DCM balance:", dogCoinMax.balanceOf(deployer));
//         console.log("Deployer XV balance:", xVentures.balanceOf(deployer));

//         uint256 Node1b = willwe.spawnBranch(rootNode1);
//         uint256 Node2b = willwe.spawnBranch(rootNode2);
//         uint256 Node3b = willwe.spawnBranch(rootNode3);
//         uint256 Node4b = willwe.spawnBranch(rootNode4);

//         uint256 Node1a = willwe.spawnBranch(Node1b);
//         uint256 Node2a = willwe.spawnBranch(Node2b);
//         uint256 Node3a = willwe.spawnBranch(Node3b);
//         uint256 Node4a = willwe.spawnBranch(Node4b);

//         console.log("mint path 1a--- 10keth");
//         willwe.mintPath(Node1a, 10_000 ether);
//         console.log("mint path 2a--- 10keth");
//         willwe.mintPath(Node2a, 3_000 ether);

//         console.log("mint path 3b--- 10keth");
//         willwe.mintPath(Node3b, 1_000 ether);
//         console.log("mint path 4b--- 10keth");
//         willwe.mintPath(Node4b, 1_000 ether);

//         vm.stopBroadcast();
//     }
// }

// //  0xAfb355d9D6e16C6F4bE2435baa1195f4889c9ED7 0x9d706Ab5E229bb36fA59BC98b8047Ad251Db898e 0x8F4b13E6306E31A1af87ccC9228bBE89c8AE54f2 0xF2F5bdDd94e38B04cD76D19450dDE5E709544895

// //   ###############################
// //   ##### Deployer :  0x259c1F1FaF930a23D009e85867A6b5206b2a6d44 | expected 0x259c1F1FaF930a23D009e85867A6b5206b2a6d44
// //   #________________________________
// //   ###############################

// //   Fun deployed at :  0x8f45bEe4c58C7Bb74CDa9fBD40aD86429Dba3E41

// //   ###############################
// //   ###############################

// //   Root Value in Control :  0xDf17125350200A99E5c06E5E2b053fc61Be7E6ae
// //   Controling Extrmity:  0xc01F390530ca36Ec1871F9E4D74b0B2aaf852A44
// //   ###############################
// //   Balances: deployer | Agent
// //   0 10000000
// //   Will Price in ETH: 1000000000

// //   ###############################

// //   ###############################
// //   Foundation Agent Safe at:  0xc01F390530ca36Ec1871F9E4D74b0B2aaf852A44
// //   Will:  0xDf17125350200A99E5c06E5E2b053fc61Be7E6ae
// //   Membrane:  0xaBbd15F9eD0cab9D174b5e9878E9f104a993B41f
// //   Execution:  0x3D52a3A5D12505B148a46B5D69887320Fc756F96
// //   WillWe:  0x8f45bEe4c58C7Bb74CDa9fBD40aD86429Dba3E41
// //   ###############################
