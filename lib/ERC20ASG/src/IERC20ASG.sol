// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IERC20ASG is IERC20 {
    //// @notice mints specified amount to msg.sender requires corresponding value
    //// @param howMany_ number of tokens wanted
    function mint(uint256 howMany_) external payable;

    //// @notice burns amount provided sender has balanace. returns coresponding available value.
    //// @param howMany_ amount to burn
    // function burn(uint256 howMany_)  external  returns (uint256 amtValReturned);

    //// @notice returns current mint price per full unit
    function currentPrice() external view returns (uint256);

    //// @notice returns cost for mint for amount at current block
    //// @param amt_ amount of units to calculate price for
    function mintCost(uint256 amt_) external view returns (uint256);

    //// @notice returns amount of ETH refunded for burining the provided amount
    //// @param amt_ amount to calculate refund from expressed as a full, non-fractionable unit (1e18)
    function burnReturns(uint256 amt_) external view returns (uint256);

    ////  @param howMany_ how many of full units to burn expressed as full units (1e18 min)
    //// @param  to_  address to send refund to
    //// @dev note that only full units are supported and full unit burn wrapper might be needed for fractional burn
    function burnTo(uint256 howMany_, address to_) external returns (uint256);

    ////  @param howMany_ how many of full units to burn expressed as full units (1e18 min)
    //// @dev note that only full units are supported and full unit burn wrapper might be needed for fractional burn
    function burn(uint256 howMany_) external returns (uint256);
}
