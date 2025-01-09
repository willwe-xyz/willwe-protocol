// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {Will} from "will/contracts/Will.sol";

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

        address[] memory founders = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        founders[0] = deployer;
        amounts[0] = 10_000_000;

        uint256 piper_sec = 1;

        vm.startBroadcast(runPVK);
        F20 = new Will(founders, amounts);
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

        FunFun.initSelfControl();

        vm.label(FunFun.control(1), "foundationSafe");
        F20.transfer(FunFun.control(1), F20.balanceOf(deployer));

        console.log("###############################");
        console.log(" ");
        console.log("Root Value in Control : ", address(FunFun.control(0)));
        console.log("Controling Extrmity: ", FunFun.control(1));

        F20.transfer(FunFun.control(1), F20.balanceOf(address(deployer)));

        console.log("###############################");
        console.log("Balances: deployer | Agent ");
        console.log(F20.balanceOf(address(deployer)), F20.balanceOf(FunFun.control(1)));
        console.log("Will Price in ETH:", F20.currentPrice());

        console.log(" ");
        console.log("###############################");
        console.log(" ");
        console.log("###############################");
        console.log("Foundation Agent Safe at: ", FunFun.control(1));
        console.log("Will: ", address(F20));
        console.log("Membrane: ", address(M));
        console.log("Execution: ", address(E));
        console.log("WillWe: ", address(FunFun));
        console.log("###############################");
        vm.stopBroadcast();
    }
}

// == Logs ==
//   ###############################

//      Deploy script started for network :  11155420

//   ###############################
//   ##### Deployer :  0x259c1F1FaF930a23D009e85867A6b5206b2a6d44 | expected 0x259c1F1FaF930a23D009e85867A6b5206b2a6d44
//   #________________________________
//   ###############################

//   Fun deployed at :  0x91Ac0Fa9A36101362814d20C00873CF0d4680a5C

//   ###############################
//   ###############################

//   Root Value in Control :  0x135288e116CA226E7Fa7BD60F002e0bc54fB062e
//   Controling Extrmity:  0x0000000000000000000000000000000000000000
//   ###############################
//   Balances: deployer | Agent
//   0 10000000
//   Will Price in ETH: 0

//   ###############################

//   ###############################
//   Foundation Agent Safe at:  0x0000000000000000000000000000000000000000
//   Will:  0x99e612d393a89798dDDE4903040659a3ae9E5932
//   Membrane:  0x3e0bb52B6440CEcAF9ecF8b0951D51F9A0B82F48
//   Execution:  0x4b2487E6C275eE0bAF3F290EE0880530fb91708f
//   WillWe:  0x91Ac0Fa9A36101362814d20C00873CF0d4680a5C
//   ###############################
