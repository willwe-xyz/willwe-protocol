// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract X20 is ERC20("AnERC20Token", "USDC") {
    constructor() {
        _mint(address(1), 1_000_000 ether);
        _mint(address(msg.sender), 1_000_000 ether);
    }
}

// contract X721 is ERC721("AnERC721Token", "aE20") {
//        constructor() {
//        }

// }

contract TokenPrep {
    function makeReturnERC20() public returns (address) {
        return address(new X20());
    }

    // function makeReturnERC721() {
    //      return address( new X721());
    // }
}
