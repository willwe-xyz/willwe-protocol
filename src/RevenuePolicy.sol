// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.18;

// import "ERC20ASG/src/IERC20ASG.sol";

// //// @notice handles revenue policy logic and storage
// abstract contract RevenuePolicy {
//     IERC20ASG coreToken;
//     uint256 coreDAO;
//     address deployer;

//     /// @notice tax rate for root token withdrawals
//     mapping(address token => uint256) revenuePolicy;
//     /// @dev address(0) -> gas multiplier for cost payment

//     constructor() {
//         revenuePolicy[address(0)] = 2;
//         deployer = address(msg.sender);
//     }

//     error CoreGasTransferFailed();
//     error OnlyDeployer();

//     event GasUsedWithCost(address indexed sender, bytes4 indexed signature, uint256 gasCost);
//     event SetCoreToken(address token);

//     modifier localGas() {
//         uint256 startGas = gasleft();
//         _;
//         if (address(coreToken) != address(0)) {
//             uint256 endGas = gasleft();
//             uint256 gasUsed = startGas - endGas;
//             // Retrieve the gas price from the transaction
//             uint256 gasPrice = tx.gasprice;
//             // Calculate the total gas cost in Ether
//             uint256 gasCost = gasUsed * gasPrice / 1e18;
//             uint256 perUnit = coreToken.burnReturns(1);
//             gasCost = gasCost * revenuePolicy[address(0)];

//             gasCost = perUnit > gasCost ? 1 ether / (perUnit / gasCost) : gasCost / perUnit;
//             if (!coreToken.transferFrom(msg.sender, address(this), gasCost)) revert CoreGasTransferFailed();
//             emit GasUsedWithCost(msg.sender, msg.sig, gasCost);
//         }
//     }

//     //// @note sets gas token of type ERC20ASG
//     ///  @param T_  token address
//     function setCoreToken(address T_) internal {
//         if (msg.sender != deployer) revert OnlyDeployer();
//         coreToken = IERC20ASG(T_);
//     }
// }
