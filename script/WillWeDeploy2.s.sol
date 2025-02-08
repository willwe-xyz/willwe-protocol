// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {Will} from "will/contracts/Will.sol";

contract Create2Factory {
    event Deployed(address addr, uint256 salt);

    function deploy(bytes memory bytecode, uint256 salt) public payable returns (address payable) {
        address addr;
        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
        return payable(addr);
    }

    function computeAddress(bytes memory bytecode, uint256 salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }
}

contract WillWeDeploy2 is Script {
    WillWe public WW;
    Execution public E;
    Will public F20;
    Create2Factory public factory;
    
    // Salt values for each contract
    uint256 constant WILL_SALT = 1;
    uint256 constant MEMBRANES_SALT = 2;
    uint256 constant EXECUTION_SALT = 3;
    uint256 constant WILLWE_SALT = 4;

    function setUp() public virtual {
        console.log("###############################");
        console.log("                                                             ");
        console.log("   Deploy script started for network : ", block.chainid);
        console.log("                                                             ");
        console.log("###############################");
    }

    function run() public {
        uint256 runPVK = uint256(vm.envUint("WILLWE_DEV_0PVK"));
        address deployer = vm.addr(runPVK);
        vm.label(deployer, "deployer");
        console.log("##### Deployer : ", deployer, "| expected", "0x259c1F1FaF930a23D009e85867A6b5206b2a6d44");
        console.log("#________________________________");

        vm.startBroadcast(runPVK);

        // Deploy CREATE2 factory if not already deployed
        factory = new Create2Factory();

        // Prepare constructor arguments
        address[] memory founders;
        uint256[] memory amounts;

        // Deploy Will with CREATE2
        bytes memory willBytecode = abi.encodePacked(
            type(Will).creationCode,
            abi.encode(founders, amounts)
        );
        address payable willAddr = factory.deploy(willBytecode, WILL_SALT);
        F20 = Will(willAddr);
        vm.label(address(F20), "Will");

        // Deploy Membranes with CREATE2
        bytes memory membranesBytes = type(Membranes).creationCode;
        address membranesAddr = factory.deploy(membranesBytes, MEMBRANES_SALT);
        Membranes M = Membranes(membranesAddr);

        // Deploy Execution with CREATE2
        bytes memory executionBytecode = abi.encodePacked(
            type(Execution).creationCode,
            abi.encode(address(F20))
        );
        address payable executionAddr = factory.deploy(executionBytecode, EXECUTION_SALT);
        E = Execution(executionAddr);

        // Deploy WillWe with CREATE2
        bytes memory willWeBytecode = abi.encodePacked(
            type(WillWe).creationCode,
            abi.encode(address(E), address(M))
        );
        address willWeAddr = factory.deploy(willWeBytecode, WILLWE_SALT);
        WW = WillWe(willWeAddr);
        
        vm.label(address(WW), "WillWe");
        WW.initSelfControl();
        vm.label(WW.control(0), "kyberfoundation");

        // Print deployment information
        console.log("###############################");
        console.log(" ");
        console.log("Control [0,1] : ", address(WW.control(0)), address(WW.control(1)));
        console.log("Will Price in ETH:", F20.currentPrice());
        console.log(" ");
        console.log("###############################");
        console.log(" ");
        console.log("###############################");
        console.log("Kibern Director at: ", WW.control(1));
        console.log("Will: ", address(F20));
        console.log("Membrane: ", address(M));
        console.log("Execution: ", address(E));
        console.log("WillWe: ", address(WW));
        console.log("###############################");

        // Print predicted addresses
        console.log("Predicted addresses:");
        console.log("Will:", factory.computeAddress(willBytecode, WILL_SALT));
        console.log("Membranes:", factory.computeAddress(membranesBytes, MEMBRANES_SALT));
        console.log("Execution:", factory.computeAddress(executionBytecode, EXECUTION_SALT));
        console.log("WillWe:", factory.computeAddress(willWeBytecode, WILLWE_SALT));

        vm.stopBroadcast();
    }
}