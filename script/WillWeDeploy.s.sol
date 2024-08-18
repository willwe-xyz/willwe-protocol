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
//   Foundation Agent Safe at:  0xa9ad58dab684b27a6d9d2d24f8303a17732bca2f
//   Will:  0x6ede1d85bbc8922e493f5507df3bcc3960599a97
//   Membrane:  0x214fea19b4ef0c3d1440398ecd0a2523dcf14210
//   Execution:  0x96b88f2b098ae65cfd93b226f1a9444ec4043ebe
//   WillWe:  0xf32f9c6004cd998bc0319290b348a1dbffc4ef67
//   ###############################



// OP - Sepolia
// == Logs ==
//   ###############################
                                                               
//      Deploy script started for network :  11155420
                                                               
//   ###############################
//   ##### Deployer :  0x259c1F1FaF930a23D009e85867A6b5206b2a6d44 | expected 0x259c1F1FaF930a23D009e85867A6b5206b2a6d44
//   #________________________________
//   ###############################
   
//   Fun deployed at :  0x264336ec33fab9CC7859b2C5b431f42020a20E75
   
//   ###############################
//   ###############################
   
//   Root Value in Control :  0x9d814170537951fE8eD28A534CDE9F30Fd731A64
//   Controling Extrmity:  0xDD9e56E94B6166f47D8F597AECeB38e72e274E92
//   ###############################
//   Balances: deployer | Agent 
//   0 10000000
//   Will Price in ETH: 1000000000
   
//   ###############################
   
//   ###############################
//   Foundation Agent Safe at:  0xDD9e56E94B6166f47D8F597AECeB38e72e274E92
//   Will:  0x9d814170537951fE8eD28A534CDE9F30Fd731A64
//   Membrane:  0x36C70f035c39e4072822F8C33C4427ae59298451
//   Execution:  0xEDf98928d9513051D75e72244e0b4DD254DB1462
//   WillWe:  0x264336ec33fab9CC7859b2C5b431f42020a20E75
//   ###############################