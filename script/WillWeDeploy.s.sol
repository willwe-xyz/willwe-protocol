// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {Will} from "../src/Will.sol";

contract WillWeDeploy is Script {
    WillWe FunFun;
    Execution E;
    Will F20;

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

        address[] memory founders;
        uint256[] memory amounts;

        uint256 piper_sec = 1;

        vm.startBroadcast(runPVK);
        //// price in gwei | price increase per second in gwei | founder addresses | amounts
        F20 = new Will(1, 1, founders, amounts);
        vm.label(address(F20), "Will");

        Membranes M = new Membranes();

        E = new Execution(address(F20));
        FunFun = new WillWe(address(E), address(M));
        vm.label(address(FunFun), "FunFun");

        console.log("###############################");
        console.log(" ");
        console.log("Fun deployed at : ", address(FunFun));
        console.log(" ");
        console.log("###############################");

        uint256 govNodeParent = FunFun.spawnRootBranch(address(F20));
        uint256 govNode = FunFun.spawnBranch(govNodeParent);
        E.setFoundationAgent(govNode);

        vm.label(E.FoundationAgent(), "foundationSafe");
        FunFun.setControl(E.FoundationAgent());

        console.log("###############################");
        console.log(" ");
        console.log("Foundation Agent in Control : ", address(E.FoundationAgent()));
        console.log("Is Foundation Anget contract: ", E.FoundationAgent());
        console.log("Deployer is member ", FunFun.isMember(deployer, govNode));

        F20.transfer(E.FoundationAgent(), F20.balanceOf(address(deployer)));
        // F20.setPointer(E.FoundationAgent());

        console.log("###############################");
        console.log("Balances: deployer | Agent | f0");
        // console.log(F20.balanceOf(address(deployer)), F20.balanceOf(E.FoundationAgent()), F20.balanceOf(founders[0]));

        console.log(" ");
        console.log("###############################");
        console.log(" ");
        console.log("###############################");
        console.log("Foundation Agent Safe at: ", E.FoundationAgent());
        console.log("Will: ", address(F20));
        console.log("Membrane: ", address(M));
        console.log("Execution: ", address(E));
        console.log("WillWe: ", address(FunFun));
        console.log("###############################");
        vm.stopBroadcast();
    }
}
