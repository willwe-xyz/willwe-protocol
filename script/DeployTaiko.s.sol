// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {Will} from "../src/Will.sol";

contract DeployTaiko is Script {
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
        uint256 runPVK = uint256(vm.envUint("WW_deployer_taiko"));
        address deployer = vm.addr(runPVK);
        vm.label(deployer, "deployer");

        console.log("##### Deployer : ", deployer, "| expected", "0x259c1F1FaF930a23D009e85867A6b5206b2a6d44");
        console.log("#________________________________");

              address deployer2 = 0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd;
        address protocol_guild = 0x32e3C7fD24e175701A35c224f2238d18439C7dBC;

        address[] memory founders = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        founders[0] = deployer;
        founders[1] = protocol_guild;
        amounts[0] = 10_000_000 * 1 ether;
        amounts[1] = 11_000_000 * 1 ether;

        uint256 piper_sec = 1 gwei / 100;

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
// == Logs ==
//   ###############################
                                                               
//      Deploy script started for network :  167009
                                                               
//   ###############################
//   ##### Deployer :  0xC9a9C487BB6f53BA8ABe8471d39358C875B388c5 | expected 0x259c1F1FaF930a23D009e85867A6b5206b2a6d44
//   #________________________________
//   ###############################
   
//   Fun deployed at :  0x1F0966dC854F6911F1Ab38752130F3158293fdCE
   
//   ###############################
//   ###############################
   
//   Root Value in Control :  0xe432f1B9463Db4500CBa0CA4101938D4548d9c88
//   Controling Extrmity:  0x8ed4Dc0d7b6Ff664b044aF0794Ca240d22A4e20b
//   ###############################
//   Balances: deployer | Agent 
//   0 10000000000000000000000000
//   Will Price in ETH: 1000000000
   
//   ###############################
   
//   ###############################
//   Foundation Agent Safe at:  0x8ed4Dc0d7b6Ff664b044aF0794Ca240d22A4e20b
//   Will:  0xe432f1B9463Db4500CBa0CA4101938D4548d9c88
//   Membrane:  0x7DA446815C1dcB9D0A009C96CE28Ed1Fcfe751ed
//   Execution:  0x9ac6503f163A5053259740fd15933a230aB2d59c
//   WillWe:  0x1F0966dC854F6911F1Ab38752130F3158293fdCE
//   ###############################