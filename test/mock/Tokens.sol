// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract X20 is ERC20("AnERC20Token", "USDC") {
    constructor() {
        _mint(address(1), 1_000_000 ether);
        _mint(address(msg.sender), 1_000_000 ether);
    }
}

contract X20RON is ERC20("Lettuce", "LET") {
    constructor() {
        _mint(address(msg.sender), 1_000_000 ether);
        _mint(address(0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd), 200_000 ether);
    }
}

contract X20RONAlias is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(address(msg.sender), 1_000_000 ether);
        _mint(address(0xE7b30A037F5598E4e73702ca66A59Af5CC650Dcd), 200_000 ether);
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

    function makeReturnX20RON() public returns (address) {
        return address(new X20RON());
    }

    function makeReturnX20RONWalias(string memory name_, string memory symbol_) public returns (address) {
        return address(new X20RONAlias(name_, symbol_));
    }
    // function makeReturnERC721() {
    //      return address( new X721());
    // }
}
