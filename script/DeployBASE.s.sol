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

contract DeployBASE is Script, TokenPrep, AliasPicker {
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
        // uint256 runPVK = uint256(vm.envUint("WEWILL_DE_PVK"));
        // address deployer = vm.addr(runPVK);

        // ////////////////// MOCK token
        // vm.label(deployer, "deployer");
        // ////////////////// MOCK

        // console.log("##### Deployer : ", deployer, "| expected", "0xB76eF2DdE3d0b8AE716272f1BB943610C77a4C93");
        // console.log("#________________________________");

        address deployer = 0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd;
        address protocol_guild = 0x32e3C7fD24e175701A35c224f2238d18439C7dBC;

        address[] memory founders = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        founders[0] = deployer;
        amounts[0] = 10_000_000 * 1 ether;
        uint256 piper_sec = 21;

        vm.startBroadcast();
        // string memory name =
        //     AliasPicker.getAlias(uint8(block.timestamp % 100 > 99 ? block.timestamp % 10 : block.timestamp % 100 + 1));
        // address randomToken = makeReturnX20RONWalias(
        //     name, string.concat(StringUtils.substring(name, 0, 2), StringUtils.substring(name, 5, 6))
        // );
        // console.log("##### mockRON token ", randomToken);
        //// [0] in gwei
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

// == Logs ==
//   ###############################

//      Deploy script started for network :  8453

//   ###############################
//   ###############################

//   Fun deployed at :  0x2316531d2358Bd040212246466a5784d01268Ff6

//   ###############################
//   control ---  0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd 0x0000000000000000000000000000000000000000 0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd
//   ###############################

//   Foundation Agent in Control :  0xa3B55A883a982A9bcC370d68D1B2D38877777D83
//   Is Foundation Anget contract:  true
//   Deployer is member  true
//   ###############################
//   Balances: deployer | Agent | f0
//   0 10000000000000000000000000 0

//   ###############################
//   Foundation Agent Safe at:  0xa3B55A883a982A9bcC370d68D1B2D38877777D83
//   RVI:  0x6CdDcBb43B7E37962E80e026b5C37391fb41c3AC
//   Membrane:  0x65F1bAA3842B6B852724E57a2006882570b07Bdf
//   Execution:  0xd3FF00A965cFa1fE6E8767EF0C46ED6AC548fF20
//   WillWe:  0x2316531d2358Bd040212246466a5784d01268Ff6
//   ###############################
