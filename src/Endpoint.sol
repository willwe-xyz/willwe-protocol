// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {SafeFactoryAddresses} from "./info/GnosisSafeFactory.sol";
import {ISafeFactory} from "./interfaces/ISafeFactory.sol";

/// @title Fungido
/// @author parseb
abstract contract Endpoints {
    ISafeFactory SafeFactory;
    address Singleton;

    constructor() {
        SafeFactory = ISafeFactory(SafeFactoryAddresses.factoryAddressForChainId(block.chainid));
        Singleton = SafeFactoryAddresses.getSingletonAddressForChainID(block.chainid);
    }

    function createNodeEndpoint(uint256 endpointOwner_) internal virtual returns (address endpoint) {
        endpoint = SafeFactory.createProxyWithNonce(Singleton, abi.encodePacked(), (endpointOwner_ - block.timestamp));
    }
}
