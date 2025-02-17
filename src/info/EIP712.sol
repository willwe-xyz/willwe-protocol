// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Movement, MovementType, SQState, SignatureQueue, Call} from "../interfaces/IExecution.sol";

// EIP712 domain separator
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
    bytes32 salt;
}

contract EIP712 {
    // EIP712 domain separator hash
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable SALT;

    // EIP712 domain separator setup
    constructor() {
        SALT = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), "SugarySalts"));

        DOMAIN_SEPARATOR = hashDomain(
            EIP712Domain({
                name: "WillWe.xyz",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this),
                salt: SALT
            })
        );
    }

    function hashDomain(EIP712Domain memory domain) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
                ),
                keccak256(bytes(domain.name)),
                keccak256(bytes(domain.version)),
                domain.chainId,
                domain.verifyingContract,
                domain.salt
            )
        );
    }

    function hashMessage(Movement memory movement) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    "Movement(uint8 category,address initiatior,address exeAccount,uint256 viaNode,uint256 expiresAt,string description,bytes executedPayload)"
                ),
                movement.category,
                movement.initiatior,
                movement.exeAccount,
                movement.viaNode,
                movement.expiresAt,
                movement.description,
                keccak256(movement.executedPayload)
            )
        );
    }

    function verifyMessage(Movement memory movement, uint8 v, bytes32 r, bytes32 s, address expectedAddress)
        public
        view
        returns (bool)
    {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashMessage(movement)));

        address recoveredAddress = ecrecover(digest, v, r, s);

        return (recoveredAddress == expectedAddress);
    }
}
