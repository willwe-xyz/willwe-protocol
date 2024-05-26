// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {RVT} from "../src/RVT.sol";

contract WillWeDeploy is Script {
    WillWe FunFun;
    Execution E;
    RVT F20;

    function setUp() public virtual {
        console.log("###############################");
        console.log("                                                             ");
        console.log("   Deploy script started for network : ", block.chainid);

        console.log("                                                             ");
        console.log("###############################");
    }

    function run() public {
        uint256 runPVK = uint256(vm.envUint("DEGEN_DEPLOYER_PVK"));
        address deployer = vm.addr(runPVK);
        vm.label(deployer, "deployer");

        console.log("##### Deployer : ", deployer, "| expected", "0x920CbC9893bF12eD967116136653240823686D9c");
        console.log("#________________________________");

        address[] memory founders = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        founders[0] = address(0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd);
        founders[1] = deployer;

        amounts[0] = 1_000_000 * 1 ether;
        amounts[1] = 1_000_000 * 1 ether;

        uint256 piper_sec = 306;

        vm.startBroadcast(runPVK);

        F20 = new RVT(1_000_000_000, piper_sec, founders, amounts);
        vm.label(address(F20), "RVT");

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
        F20.setPointer(E.FoundationAgent());

        console.log("###############################");
        console.log("Balances: deployer | Agent | f0");
        console.log(F20.balanceOf(address(deployer)), F20.balanceOf(E.FoundationAgent()), F20.balanceOf(founders[0]));

        console.log(" ");
        console.log("###############################");
        console.log(" ");
        console.log("###############################");
        console.log("Foundation Agent Safe at: ", E.FoundationAgent());
        console.log("RVT: ", address(F20));
        console.log("Membrane: ", address(M));
        console.log("Execution: ", address(E));
        console.log("WillWe: ", address(FunFun));
        console.log("###############################");
        vm.stopBroadcast();
    }
}
