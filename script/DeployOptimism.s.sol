// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {Will} from "../src/Will.sol";
import {TokenPrep} from "../test/mock/Tokens.sol";
import {AliasPicker} from "./Alias.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {StringUtils} from "./StringSlicer.sol";

contract DeployOptimism is Script, TokenPrep, AliasPicker {
    using StringUtils for string;

    WillWe FunFun;
    Execution E;
    Will F20;

    //// @dev FoundingAgent transit value.

    function setUp() public virtual {
        console.log("###############################");
        console.log("                                                             ");
        console.log("   Deploy script started for network : ", block.chainid);

        console.log("                                                             ");
        console.log("###############################");
    }

    function run() public {
        uint256 runPVK = uint256(vm.envUint("WW_deployer2"));
        address deployer = vm.addr(runPVK);

        ////////////////// MOCK token
        vm.label(deployer, "deployer");
        ////////////////// MOCK

        console.log("##### Deployer : ", deployer, "| expected", "0x73D94e40a4958E350418b790ab180107B9892a4c");
        console.log("#________________________________");

        address deployer2 = 0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd;
        address protocol_guild = 0x32e3C7fD24e175701A35c224f2238d18439C7dBC;
        
        address[] memory founders = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        founders[0] = deployer2;
        amounts[0] = 10_000_000 * 1 ether;
        uint256 piper_sec = 21;

        vm.startBroadcast();
        F20 = new Will(36, piper_sec, founders, amounts);
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
        // E.setFoundingAgent(govNode);

        address FA = FunFun.initSelfControl();
        vm.label(FA, "foundationSafe");

        console.log("control --- ", (FunFun.control(0)), (FunFun.control(1)), deployer);

        console.log("###############################");
        console.log(" ");
        console.log("Foundation Agent in Control : ", FA);
        console.log("Is Foundation Anget contract: ", (address(FunFun.control(1)).code.length > 1));
        console.log("Deployer is member ", FunFun.isMember(deployer, govNode));

        if ((address(FA).code.length > 2)) {
            // F20.setPointer(FA);
            F20.transfer(FA, F20.balanceOf(address(deployer)));
        } else {
            console.log("foundation not safe");
        }

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

