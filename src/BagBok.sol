// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Fun} from "./Fun.sol";

/// @title BagBok
/// @author parseb
/// @notice Experimental. Do not use.
contract BagBok is Fun {
    constructor(address Execution, address Membrane) Fun(Execution, Membrane) {}
}
