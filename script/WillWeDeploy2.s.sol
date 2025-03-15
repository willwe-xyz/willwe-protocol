// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {Will} from "will/contracts/Will.sol";

contract WillWeDeploy2 is Script {
    WillWe public WW;
    Execution public E;
    Will public F20;
    address public membranesAddr;

    error ContractAlreadyDeployed(address addr);

    struct DeploymentConfig {
        bytes bytecode;
        uint256 salt;
        string label;
        bool isPayable;
    }

    function setUp() public virtual {
        console.log("Deploy script started for network:", block.chainid);
        console.log("Block timestamp (will be used as salt):", block.timestamp);
    }

    function deploy(DeploymentConfig memory config) internal returns (address addr) {
        console.log("\n=== Starting deployment for:", config.label, "===");

        // Check predicted address first
        bytes32 salt = bytes32(config.salt);
        bytes32 initCodeHash = keccak256(config.bytecode);
        address predictedAddress = vm.computeCreate2Address(salt, initCodeHash);

        console.log("Predicted address:", predictedAddress);

        // Check if there's already code at the predicted address
        uint256 size;
        assembly {
            size := extcodesize(predictedAddress)
        }
        if (size > 0) {
            console.log("WARNING: Code already exists at predicted address!");
            revert ContractAlreadyDeployed(predictedAddress);
        }

        console.log("No existing code found at predicted address, proceeding with deployment...");

        assembly {
            addr := create2(0, add(mload(config), 0x20), mload(mload(config)), mload(add(config, 0x20)))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        console.log("Deployment successful! Address:", addr);

        if (bytes(config.label).length > 0) {
            vm.label(addr, config.label);
        }
    }

    function generateBytecode(bytes memory creationCode, bytes memory args) internal pure returns (bytes memory) {
        return args.length > 0 ? abi.encodePacked(creationCode, args) : creationCode;
    }

    function deployAllContracts() internal {
        // Prepare constructor arguments
        address[] memory founders;
        uint256[] memory amounts;
        console.log("Prepared empty founders and amounts arrays");

        // Deploy Will
        console.log("\nDeploying Will contract...");
        F20 = Will(
            payable(
                deploy(
                    DeploymentConfig({
                        bytecode: generateBytecode(type(Will).creationCode, abi.encode(founders, amounts)),
                        salt: block.timestamp + 1,
                        label: "Will",
                        isPayable: true
                    })
                )
            )
        );
        console.log("Will contract deployed successfully");

        // Deploy Membranes
        console.log("\nDeploying Membranes contract...");
        membranesAddr = deploy(
            DeploymentConfig({
                bytecode: type(Membranes).creationCode,
                salt: block.timestamp + 2,
                label: "Membranes",
                isPayable: false
            })
        );
        Membranes M = Membranes(membranesAddr);
        console.log("Membranes contract deployed successfully");

        // Deploy Execution
        console.log("\nDeploying Execution contract...");
        E = Execution(
            payable(
                deploy(
                    DeploymentConfig({
                        bytecode: generateBytecode(type(Execution).creationCode, abi.encode(address(F20))),
                        salt: block.timestamp + 3,
                        label: "Execution",
                        isPayable: true
                    })
                )
            )
        );
        console.log("Execution contract deployed successfully");

        // Deploy WillWe
        console.log("\nDeploying WillWe contract...");
        WW = WillWe(
            deploy(
                DeploymentConfig({
                    bytecode: generateBytecode(type(WillWe).creationCode, abi.encode(address(E), address(M))),
                    salt: block.timestamp + 4,
                    label: "WillWe",
                    isPayable: false
                })
            )
        );
        console.log("WillWe contract deployed successfully");

        // Initialize WillWe
        console.log("\nInitializing WillWe contract...");
        WW.initSelfControl();
        vm.label(WW.control(0), "kiber");
        console.log("WillWe initialization complete");
    }

    function logDeployments() internal view {
        console.log("\n=== Final Deployment Addresses ===");
        console.log("Will:", address(F20));
        console.log("Membrane:", membranesAddr);
        console.log("Execution:", address(E));
        console.log("WillWe:", address(WW));
        console.log("Kibern Director:", WW.control(1));
        console.log("Control [0,1]:", WW.control(0), WW.control(1));
        console.log("Will Price in ETH:", F20.currentPrice());
    }

    function run() public {
        console.log("\n=== Starting deployment process ===");
        uint256 runPVK = uint256(vm.envUint("PARSEB_306"));
        address deployer = vm.addr(runPVK);
        console.log("Deployer address:", deployer);

        // Check deployer balance
        uint256 balance = deployer.balance;
        console.log("Deployer balance:", balance, "wei");

        vm.startBroadcast(runPVK);

        // Execute deployments
        deployAllContracts();
        logDeployments();

        vm.stopBroadcast();
    }
}
