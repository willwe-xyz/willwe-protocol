// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {BagBok} from "../src/BagBok.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {RVT} from "../src/RVT.sol";

contract BagBokDeploy is Script {
    BagBok FunFun;
    Execution E;
    RVT F20;

    function setUp() public {
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

        console.log("##### Deployer : ", deployer,  "| expected", "0x920CbC9893bF12eD967116136653240823686D9c");
        console.log("#________________________________");

        address[] memory founders = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        founders[0] = address(0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd);
        founders[1] = deployer;

        uint256 one = 1_000_000_000;
        amounts[0] = 1_000_000 * one;
        amounts[1] = 1_000_000 * one;

        uint256 piper_sec = one / 86400 / 1 gwei;

        vm.startBroadcast(runPVK);

        F20 = new RVT(one, piper_sec, founders, amounts);
        vm.label(address(F20), "deployer");

        Membranes M = new Membranes();

        E = new Execution(address(F20));
        FunFun = new BagBok(address(E), address(M));
        vm.label(address(FunFun), "FunFun");

        uint256 rootBranchId = FunFun.spawnRootBranch(address(F20));
        uint256 commonBranch = FunFun.spawnBranch(rootBranchId);

 /*        FunFun.mintMembership(commonBranch, address(E));

        address fa_ = FunFun.createEndpointForOwner( commonBranch, address(E));  */

        E.setFoundationAgent(commonBranch);

        console.log("###############################");
        console.log(" ");
        console.log("Fun deployed at : ", address(FunFun));
        console.log(" ");
        console.log("###############################");
        vm.label( E.FoundationAgent(), "foundationSafe");
        FunFun.setControl(E.FoundationAgent());

        console.log("###############################");
        console.log(" ");
        console.log("Foundation Agent in Control : ", address(E.FoundationAgent()));
        console.log(" ");
        console.log("###############################");
/* 
        address[] memory to = new address[](1);
        uint256[] memory amt = new uint256[](1);

        to[0] = address(F20);
        amt[0] = 1000 * one;

        console.log("root node", rootNode);
        
            uint256 membraneID = M.createMembrane(to, amt, "metadata");
            uint256[] memory signals = new uint256[](2);
            signals[0] = membraneID;
            signals[1] = 1_000_000_000;
            if (!FunFun.isMember(deployer, rootNode)) FunFun.mintMembership(rootNode, deployer);

            FunFun.sendSignal(rootNode, signals);

            console.log("RootNodeID | Membrane ID | CurrentInflation");
            console.log(rootNode, membraneID, FunFun.inflationOf(rootNode));
        

        /// #############

        F20.transfer(E.FoundationAgent(), F20.balanceOf(address(deployer)));
        console.log("Balances: Deployer | Foundation Safe | parseb");
        console.log(
            F20.balanceOf(address(deployer)),
            F20.balanceOf(address(E.FoundationAgent())),
            F20.balanceOf(address(founders[0]))
        ); */

        // F20.setPointer(E.FoundationAgent());

        // console.log("////////////////////////////////////");
        // uint256 inflationRate = FunFun.inflationOf(rootNode);
        // console.log("Inflation Rate: ", inflationRate);
 


        vm.stopBroadcast();
    }
}
