/* 
888888b.                     888888b.            888      
888  "88b                    888  "88b           888      
888  .88P                    888  .88P           888      
8888888K.   8888b.   .d88b.  8888888K.   .d88b.  888  888 
888  "Y88b     "88b d88P"88b 888  "Y88b d88""88b 888 .88P 
888    888 .d888888 888  888 888    888 888  888 888888K  
888   d88P 888  888 Y88b 888 888   d88P Y88..88P 888 "88b 
8888888P"  "Y888888  "Y88888 8888888P"   "Y88P"  888  888 
                         888                              
                    Y8b d88P                              
                     "Y88P"                               
                                                        */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Fun} from "./Fun.sol";

/// @title WillWe
/// @author parseb
/// @notice Experimental. Do not use.
contract WillWe is Fun {
    constructor(address Execution, address Membrane) Fun(Execution, Membrane) {}
}
