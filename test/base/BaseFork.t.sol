// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.25;

// import {InitTest} from "./Init.t.sol";

// import {Will} from "../will/contracts/Will.sol";
// import {WillWe} from "../../src/WillWe.sol";
// import {Movement, Call} from "../../src/interfaces/IExecution.sol";
// import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import {IPowerProxy} from "../../src/interfaces/IPowerProxy.sol";

// contract BaseReBased is InitTest {
//     address payable public WillOnBase = payable(address(0x6CdDcBb43B7E37962E80e026b5C37391fb41c3AC));
//     address public WillWeBase = 0x2316531d2358Bd040212246466a5784d01268Ff6;
//     address public parseb_eth = 0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd;
//     address public proxyAgent = 0xa3B55A883a982A9bcC370d68D1B2D38877777D83;

//     uint256 endpointOwner = 1210283800312505576802985017589078370463982878496;

//     /// 0xd3FF00A965cFa1fE6E8767EF0C46ED6AC548fF20 Execution
//     uint256 rootNode = 621517213061799938017081734844367376392634090412;
//     uint256 node_owner_of_endpoint = 621517213061799938017081734844367376390914260929;
//     uint256 endpoint_256 = 934609816987240961991242098015378830614869802371;

//     uint256 n2 = 934609816987240961991242098015378830614869802371;
//     uint256 n1 = 621517213061799938017081734844367376390914260929;

//     uint256 nx = 621517213061799938017081734844367376390914260913;
//     uint256 public node;
//     /// initial governance node dominated by proxy agent in base deployment
//     WillWe W_W;
//     Will W20;

//     function setUp() public virtual override {
//         super.setUp();
//         vm.label(WillWeBase, "WillWeBase");

//         W_W = WillWe(WillWeBase);
//         W20 = Will(WillOnBase);
//         vm.createSelectFork("http://127.0.0.1:8545", 17136084);
//     }

//     function testAssumptions() public {
//         assertTrue(W20.balanceOf(parseb_eth) > 1, "balance not bigger than 1");
//         assertTrue(W20.balanceOf(parseb_eth) == 5, "balance 5");
//         assertTrue(
//             W20.balanceOf(0xa3B55A883a982A9bcC370d68D1B2D38877777D83) == 10_000_000 ether, "unexpected proxy change"
//         );
//         assertTrue(W20.totalSupply() > W20.balanceOf(0xa3B55A883a982A9bcC370d68D1B2D38877777D83), "all supply rip");
//         assertTrue(W_W.allMembersOf(n1).length == 0, "has members");
//         assertTrue(
//             W_W.getParentOf(W_W.getParentOf(216173341631589399165487849800707976532373169539))
//                 == W_W.getParentOf(216173341631589399165487849800707976532373169539),
//             "not level 1"
//         );
//     }

//     function _calldataTx() public returns (Call memory S) {
//         S.target = address(address(W20));
//         bytes memory data0 = abi.encodeWithSelector(IERC20.transfer.selector, parseb_eth, 10_000_000 ether); //0xa9059cbb000000
//         S.callData = data0;

//         Call[] memory calls = new Call[](1);
//         calls[0] = S;

//         bytes memory tryAggregateCall = abi.encodeWithSelector(IPowerProxy.tryAggregate.selector, true, calls);
//         S.callData = tryAggregateCall;
//         S.target = proxyAgent;
//     }

//     function testPrepareState() public {
//         vm.startPrank(parseb_eth);
//         // W_W.mintMembership(n1);
//         // W_W.mintMembership(n1);
//         // assertTrue(W_W.isMember(parseb_eth, node), 'expected member');
//         // assertTrue(W_W.isMember(parseb_eth, n1), 'expected member 2');
//         W_W.spawnRootNode(address(1210283800312505576802985017589078370463982878496));
//         W_W.mintMembership(1210283800312505576802985017589078370463982878496);

//         W20.approve(address(W_W), 11_000_000 ether);
//         W_W.mintPath(nx, W20.balanceOf(parseb_eth));
//         // W_W.mintMembership(nx);

//         uint256 snap0 = vm.snapshot();
//         Call memory transferCall = _calldataTx();

//         bytes32 moveHash = W_W.startMovement(
//             2,
//             1210283800312505576802985017589078370463982878496,
//             2,
//             transferCall.target,
//             keccak256("aaaaaaa"),
//             transferCall.callData
//         );
//         assertTrue(W20.balanceOf(parseb_eth) < 1 ether);

//         W_W.executeQueue(moveHash);

//         assertTrue(W20.balanceOf(parseb_eth) > 9_000_000 ether);
//         vm.stopPrank();
//     }
// }
