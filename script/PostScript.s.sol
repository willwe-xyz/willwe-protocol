// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {WillWe} from "../src/WillWe.sol";
import {Execution} from "../src/Execution.sol";
import {Membranes} from "../src/Membranes.sol";
import {RVT} from "../src/RVT.sol";

//// @notice !
contract WillWeDeploy is Script {
    WillWe FunFun;
    Execution E;
    RVT F20;
    Membranes M;
    uint256 govNodeParent;
    uint256 rootNode;
    uint256 interim;
    uint256 govNode;

    address deployer;

    address[] founders;
    uint256[] amounts;
    uint256 piper_sec;
    /* 
    function setUp() public {
        console.log("###############################");
        console.log("                                                             ");
        console.log("   Deploy script started for network : ", block.chainid);

        M = Membranes(0x9B94428204D2988078c5296202450d615279358c);
        E = Execution(0x984c510F515a1c0F9a254A421B60F80ec56D1439);
        F20 = RVT(0x3954625a8CB896DC5076E790F397DF9ce6Ca339b);
        FunFun = WillWe(0x1C51DeBD74b8f8aCf7BD1F6e9606195af65285AC);
        rootNode = 327294304350120122462208761167117298133480649627;
        govNodeParent = 327294304350120122462208761167117298131766957534;

        uint256 runPVK = uint256(vm.envUint("DEGEN_DEPLOYER_PVK"));
        deployer = vm.addr(runPVK);

        console.log("                                                             ");
        console.log("###############################");

        founders = new address[](2);
        amounts = new uint256[](2);

        founders[0] = address(0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd);
        founders[1] = deployer;

        amounts[0] = 1_000_000 * 1 ether;
        amounts[1] = 1_000_000 * 1 ether;

        piper_sec = uint256(1_000_000_000) / 86400;
    }

    function run() public {
        uint256 runPVK = uint256(vm.envUint("DEGEN_DEPLOYER_PVK"));

        console.log("##### Deployer : ", deployer, "| expected", "0x920CbC9893bF12eD967116136653240823686D9c");
        console.log("#________________________________");

        /* 
         address[] memory to = new address[](1);
        uint256[] memory amt = new uint256[](1);

        to[0] = address(F20);
        amt[0] = 1000 * 1_000_000_000;
        */
    /* vm.startBroadcast(runPVK);
        //////////////////////////////////////////////////////
        
        F20 = new RVT(1_000_000_000, piper_sec, founders, amounts);
        vm.label(address(F20), "deployer");
        Membranes M = new Membranes();
        E = new Execution(address(F20));
        FunFun = new WillWe(address(E), address(M));
        vm.label(address(FunFun), "FunFun"); */

    ////////////////////////////////////////////

    /*         rootNode =  FunFun.spawnRootBranch(address(F20));
        interim = FunFun.spawnBranch(rootNode);
        E.setFoundationAgent(interim);  
        govNode = FunFun.getChildrenOf(interim)[0]; */

    ///////////////////////////////////////////////////
    /*  uint256 interim = 332058949503282785974714782901888092358003302899;
        govNode = govNodeParent;

        console.log("parentOfRootNodeisSelf", rootNode, FunFun.getParentOf(rootNode));
        console.log("parentOfGove is interim", interim, FunFun.getParentOf(govNode));
        console.log("parent Of interim is root", rootNode, FunFun.getParentOf(interim));
        console.log("children of gov is none", FunFun.getChildrenOf(govNode).length == 0);
        console.log("deployer is member of interim", FunFun.isMember(deployer, interim));

        ////////////////////////////////

        address[] memory to = new address[](1);
        uint256[] memory amt = new uint256[](1);

        to[0] = address(F20);
        amt[0] = 1000 * 1_000_000_000;

        uint256 membraneID = M.createMembrane(to, amt, "metadata");
        uint256[] memory signals = new uint256[](2);
        signals[0] = membraneID;
        signals[1] = 1_000_000_000;

        console.log(FunFun.isMember(deployer, rootNode));
        console.log(FunFun.isMember(deployer, govNodeParent));

        FunFun.allMembersOf(rootNode);
        FunFun.allMembersOf(govNodeParent);

        FunFun.getParentOf(rootNode);
        FunFun.getParentOf(govNodeParent);
        FunFun.getChildrenOf(rootNode);
        FunFun.getChildrenOf(govNodeParent);

        console.log("interim - ", interim);
        console.log(FunFun.isMember(deployer, interim));

        FunFun.mintMembership(interim, deployer);
        ///FunFun.sendSignal(interim, signals);

        console.log(FunFun.isMember(deployer, interim));

        // FunFun.sendSignal(interim, signals);

        console.log("RootNodeID | Membrane ID | CurrentInflation");
        console.log(govNodeParent, membraneID, FunFun.inflationOf(interim));

        /// #############

        F20.transfer(E.FoundationAgent(), F20.balanceOf(address(deployer)));
        console.log("Balances: Deployer | Foundation Safe | parseb");
        console.log(F20.balanceOf(address(deployer)), F20.balanceOf(address(E.FoundationAgent())));

        F20.setPointer(E.FoundationAgent());


        vm.stopBroadcast(); 
    } */
}
