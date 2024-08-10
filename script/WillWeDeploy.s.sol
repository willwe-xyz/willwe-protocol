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

        address[] memory founders = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        founders[0] = deployer;
        amounts[0] = 10_000_000;

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

// Base Sepolia
//   ###############################
//   Foundation Agent Safe at:  0xe3875F069bEA20cAC8e42f255cFDf1bCA4c541c8
//   Will:  0x590fdD5Fbe567Fe1BF4941411bD6595d4A60E376
//   Membrane:  0x2Ce56E963cDD9665519153Fb3B28Ab9cC764D96b
//   Execution:  0xf8b7C3571e4db075ccDE35383F7c3f5B49BFf70C
//   WillWe:  0x0F9cAaA579275A0bf329A12e510367B938C4C58d
//   ###############################