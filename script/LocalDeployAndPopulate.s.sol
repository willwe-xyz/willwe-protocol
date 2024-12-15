// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.25;

// import "forge-std/Script.sol";
// import "../src/WillWe.sol";
// import "../src/Execution.sol";
// import "../src/Membranes.sol";
// import "will/contracts/Will.sol";
// import "../test/mock/Tokens.sol";

// /// @notice starts anvil, deploys contracts, mock tokens and
// contract DeployAndPopulate is Script, TokenPrep {
//     address[] initAddresses;
//     address deployer;
//     Will rootValueToken;
//     Execution execution;
//     Membranes membranes;
//     WillWe willwe;

//     function setUp() public {}

//     function run() public {
//         string memory mnemonic = vm.envString("MNEMONIC_DEV");
//         uint256 deployerPrivateKey = vm.deriveKey(mnemonic, 0);

//         deployer = vm.addr(deployerPrivateKey);
//         vm.label(deployer, "Deployer");
//         vm.deal(deployer, 1000 ether);
//         generateInitialAddresses(mnemonic);
//         deployContracts(deployerPrivateKey);
//         setupFruitTokens(deployerPrivateKey);
//         logInitialAddresses();
//     }

//     function generateInitialAddresses(string memory mnemonic) internal {
//         initAddresses.push(deployer); // Add deployer first
//         vm.label(deployer, "Deployer");
//         for (uint32 i = 1; i < 5; i++) {
//             uint256 privateKey = vm.deriveKey(mnemonic, i);
//             address addr = vm.addr(privateKey);
//             initAddresses.push(addr);
//             vm.deal(addr, 10 ether);
//             vm.label(addr, string(abi.encodePacked("InitAddress", vm.toString(i))));
//         }
//         vm.deal(deployer, 10 ether); // Ensure deployer also has ETH
//     }

//     function deployContracts(uint256 deployerPrivateKey) internal {
//         vm.startBroadcast(deployerPrivateKey);

//         console.log("Deploying contracts from:");
//         console.log(deployer);

//         uint256 initialPrice = 1 gwei / 100;
//         uint256 pricePerSecond = 1 gwei;
//         uint256 initialMintAmount = 1000 ether;

//         uint256[] memory initMintAmts = new uint256[](5);
//         for (uint256 i = 0; i < 5; i++) {
//             initMintAmts[i] = initialMintAmount;
//         }

//         rootValueToken = new Will(initialPrice, pricePerSecond, initAddresses, initMintAmts);
//         vm.label(address(rootValueToken), "RootValueToken");
//         console.log("Root Value Token (Will) deployed to:");
//         console.log(address(rootValueToken));

//         execution = new Execution(address(rootValueToken));
//         vm.label(address(execution), "Execution");
//         console.log("Execution deployed to:");
//         console.log(address(execution));

//         membranes = new Membranes();
//         vm.label(address(membranes), "Membranes");
//         console.log("Membranes deployed to:");
//         console.log(address(membranes));

//         willwe = new WillWe(address(execution), address(membranes));
//         vm.label(address(willwe), "WillWe");
//         console.log("WillWe deployed to:");
//         console.log(address(willwe));

//         execution.setWillWe(address(willwe));

//         vm.stopBroadcast();
//     }

//     function setupFruitTokens(uint256 deployerPrivateKey) internal {
//         vm.startBroadcast(deployerPrivateKey);

//         string[5] memory fruitNames = ["Apple", "Banana", "Cherry", "Date", "Elderberry"];
//         string[5] memory fruitSymbols = ["APPL", "BANA", "CHRY", "DATE", "ELDR"];

//         for (uint256 i = 0; i < 5; i++) {
//             address tokenAddress =
//                 makeReturnX20RONWalias(string(abi.encodePacked(fruitNames[i], " Token")), fruitSymbols[i]);
//             vm.label(tokenAddress, string(abi.encodePacked(fruitNames[i], "Token")));

//             IERC20 fruitToken = IERC20(tokenAddress);

//             uint256 bal1 = fruitToken.balanceOf(deployer);
//             console.log("bal at spawn", bal1);
//             uint256 rootBranch = willwe.spawnRootBranch(tokenAddress);
//             uint256 subBranch1 = willwe.spawnBranch(rootBranch);
//             // uint256 subSubBranch2 = willwe.spawnBranch(subBranch1);
//             fruitToken.approve(address(willwe), type(uint256).max);

//             console.log(rootBranch);

//             willwe.mint(rootBranch, bal1 / 2);
//             // vm.sleep(2000);
//             // willwe.mint(  subBranch1, bal1 / 20 );
//             // willwe.mintPath(subSubBranch, bal1 / 3 );

//             // console.log(string(abi.encodePacked("Setup completed for ", fruitNames[i], " Token")));
//         }

//         vm.stopBroadcast();
//     }

//     function logInitialAddresses() internal view {
//         console.log("Initial Addresses:");
//         for (uint256 i = 0; i < initAddresses.length; i++) {
//             console.log(string(abi.encodePacked("Address ", vm.toString(i + 1), ":")));
//             console.log(initAddresses[i]);
//             console.log("ETH Balance:");
//             console.log(initAddresses[i].balance);
//             console.log("Will Token Balance:");
//             console.log(rootValueToken.balanceOf(initAddresses[i]));
//         }
//     }
// }
