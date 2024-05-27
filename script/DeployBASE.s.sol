// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {Will} from "../src/Will.sol";
import {TokenPrep} from "../test/mock/Tokens.sol";

contract DeployBASE is Script, TokenPrep {
    WillWe FunFun;
    Execution E;
    Will F20;

    //// @dev foundationAgent transit value.

    function setUp() public virtual {
        console.log("###############################");
        console.log("                                                             ");
        console.log("   Deploy script started for network : ", block.chainid);

        console.log("                                                             ");
        console.log("###############################");
    }

    function run() public {
        uint256 runPVK = uint256(vm.envUint("BASE_DEP_PVK4"));
        address deployer = vm.addr(runPVK);

        ////////////////// MOCK token
        address randomToken = makeReturnX20RON();
        vm.label(deployer, "deployer");
        console.log("##### mockRON token ", randomToken);
        ////////////////// MOCK

        console.log("##### Deployer : ", deployer, "| expected", "0xcEEeDDD949C41b1086FC7Aa6d953a8c254160A90");
        console.log("#________________________________");

        address[] memory founders = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        founders[0] = deployer;

        /// address(0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd);
        amounts[0] = 10_000_000 * 1 ether;

        uint256 piper_sec = 69;

        vm.startBroadcast(runPVK);

        F20 = new Will(1_000_000_000, piper_sec, founders, amounts);
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

        address FA = E.FoundationAgent();
        vm.label(FA, "foundationSafe");

        console.log("control --- ", (FunFun.control(0)), (FunFun.control(1)), deployer);

        console.log("###############################");
        console.log(" ");
        console.log("Foundation Agent in Control : ", FA);
        console.log("Is Foundation Anget contract: ", (address(E.FoundationAgent()).code.length > 1));
        console.log("Deployer is member ", FunFun.isMember(deployer, govNode));

        if ((address(FA).code.length > 2)) {
            F20.setPointer(FA);
            F20.transfer(FA, F20.balanceOf(address(deployer)));
        } else {
            console.log("foundation not safe");
        }

        FunFun.setControl(FA);
        FunFun.setControl(FA);

        console.log("###############################");
        console.log("Balances: deployer | Agent | f0");
        console.log(F20.balanceOf(address(deployer)), F20.balanceOf(FA), F20.balanceOf(founders[0]));

        console.log(" ");
        console.log("###############################");
        console.log("Foundation Agent Safe at: ", FA);
        console.log("RVI: ", address(F20));
        console.log("Membrane: ", address(M));
        console.log("Execution: ", address(E));
        console.log("WillWe: ", address(FunFun));
        console.log("###############################");

        vm.stopBroadcast();
    }
}
