// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract PureUtils {
    function uintArrayToStringArray(uint256[] memory input) internal pure returns (string[] memory) {
        string[] memory result = new string[](input.length);

        for (uint256 i = 0; i < input.length; i++) {
            result[i] = Strings.toString(input[i]);
        }

        return result;
    }
}
