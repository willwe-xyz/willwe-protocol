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
    }

    function deploy(DeploymentConfig memory config) internal returns (address addr) {
        // Check predicted address first
        bytes32 salt = bytes32(config.salt);
        bytes32 initCodeHash = keccak256(config.bytecode);
        address predictedAddress = vm.computeCreate2Address(salt, initCodeHash);

        // Check if there's already code at the predicted address
        uint256 size;
        assembly {
            size := extcodesize(predictedAddress)
        }
        if (size > 0) {
            revert ContractAlreadyDeployed(predictedAddress);
        }

        assembly {
            addr := create2(0, add(mload(config), 0x20), mload(mload(config)), mload(add(config, 0x20)))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        if (bytes(config.label).length > 0) {
            vm.label(addr, config.label);
        }
    }

    function generateBytecode(bytes memory creationCode, bytes memory args) internal pure returns (bytes memory) {
        return args.length > 0 ? abi.encodePacked(creationCode, args) : creationCode;
    }

    function run() public {
        uint256 runPVK = uint256(vm.envUint("WILLWE_DEV_0PVK"));
        address deployer = vm.addr(runPVK);
        vm.label(deployer, "deployer");

        vm.startBroadcast(runPVK);

        try this.deployContracts() {
            this.logDeployments();
        } catch Error(string memory reason) {
            console.log("Deployment failed:", reason);
        } catch (bytes memory) {
            console.log("Deployment failed with low-level error");
        }

        vm.stopBroadcast();
    }

    function deployContracts() external {
        // Prepare constructor arguments
        address[] memory founders;
        uint256[] memory amounts;

        // Deploy Will
        F20 = Will(
            payable(
                deploy(
                    DeploymentConfig({
                        bytecode: generateBytecode(type(Will).creationCode, abi.encode(founders, amounts)),
                        salt: block.timestamp,
                        label: "Will",
                        isPayable: true
                    })
                )
            )
        );

        // Deploy Membranes
        membranesAddr = deploy(
            DeploymentConfig({
                bytecode: type(Membranes).creationCode,
                salt: block.timestamp,
                label: "Membranes",
                isPayable: false
            })
        );
        Membranes M = Membranes(membranesAddr);

        // Deploy Execution
        E = Execution(
            payable(
                deploy(
                    DeploymentConfig({
                        bytecode: generateBytecode(type(Execution).creationCode, abi.encode(address(F20))),
                        salt: block.timestamp,
                        label: "Execution",
                        isPayable: true
                    })
                )
            )
        );

        // Deploy WillWe
        WW = WillWe(
            deploy(
                DeploymentConfig({
                    bytecode: generateBytecode(type(WillWe).creationCode, abi.encode(address(E), address(M))),
                    salt: block.timestamp,
                    label: "WillWe",
                    isPayable: false
                })
            )
        );

        // Initialize WillWe
        WW.initSelfControl();
        vm.label(WW.control(0), "kyberfoundation");
    }

    function logDeployments() external view {
        console.log("Deployment Addresses:");
        console.log("Will:", address(F20));
        console.log("Membrane:", membranesAddr);
        console.log("Execution:", address(E));
        console.log("WillWe:", address(WW));
        console.log("Kibern Director:", WW.control(1));
        console.log("Control [0,1]:", WW.control(0), WW.control(1));
        console.log("Will Price in ETH:", F20.currentPrice());
    }
}
