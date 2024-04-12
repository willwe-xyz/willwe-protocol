// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20ASG} from "ERC20ASG/src/IERC20ASG.sol";

interface IRVT is IERC20ASG {
    /// @notice burns amount of token and retrieves underlying value as well as corresponding share of specified tokens
    ///
    function deconstructBurn(uint256 amountToBurn_, address[] memory tokensToRedeem)
        external
        returns (uint256 shareBurned);

    function simpleBurn(uint256 amountToBurn_) external returns (uint256 amtValReturned);

    function pingInit() external;

    function transferGas(address from, address to, uint256 amount) external returns (bool);
}
