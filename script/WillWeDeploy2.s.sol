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

        vm.startBroadcast(runPVK);
        F20 = new Will(founders, amounts);
        vm.label(address(F20), "Will");

        Membranes M = new Membranes();

        E = new Execution(address(F20));
        WW = new WillWe(address(E), address(M));
        vm.label(address(WW), "WillWe");

        WW.initSelfControl();

        vm.label(WW.control(0), "kyberfoundation");

        console.log("###############################");
        console.log(" ");
        console.log("Root Value in Control : ", address(WW.control(0)));
        console.log("Controling Extrmity: ", WW.control(1));
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
        vm.stopBroadcast();
    }
}
