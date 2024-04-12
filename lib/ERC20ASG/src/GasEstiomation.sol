// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.18;

// import {IERC20ASG} from "./IERC20ASG.sol";
// import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

// abstract contract TokenAsGas {

//     event GasUsedWithCost(address indexed sender, bytes4 indexed signature, uint256 gasUsed, uint256 gasCost);

//     modifier gasEstimation() {
//         uint256 startGas = gasleft();
//         _;
//         uint256 endGas = gasleft();
//         uint256 gasUsed = startGas - endGas;

//         // Retrieve the gas price from the transaction
//         uint256 gasPrice = tx.gasprice;

//         // Calculate the total gas cost in Ether
//         uint256 gasCost = gasUsed * gasPrice / 1e18;

//         emit GasUsedWithCost(msg.sender, msg.sig, gasUsed, gasCost);
//     }
// }
