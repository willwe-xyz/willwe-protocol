pragma solidity ^0.8.19;


/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */

/// @author parseb.eth @ github.com/parseb
/// ---------------------------------------
/// @author Michael Elliot <mike@makerdao.com>
/// @author Joshua Levine <joshua@makerdao.com>
/// @author Nick Johnson <arachnid@notdot.net>
/// @author OpenZeppelin OpenZeppelin.com

/// @notice A simple authenticated proxy. A mashup of (MakerDAO) MulticallV2 and simple (OpenZeppelin) proxy.
contract  PowerProxy {

    address public owner;
    address implementation;
    

    constructor() {
        owner = msg.sender;
    }

    struct Call {
        address target;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    error noFallback();
    error NotOwner();
    error Multicall2();


    function tryAggregate(bool requireSuccess, Call[] calldata calls) public returns (Result[] memory returnData) {
        if (msg.sender != owner) revert NotOwner();
        returnData = new Result[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

            if (requireSuccess && (! success)) revert Multicall2();

            returnData[i] = Result(success, ret);
        }
    }

    function setImplOrOwner(address implementation_) external {
        if (msg.sender != owner) revert NotOwner();
        if (implementation_ != implementation) implementation = implementation_;
        if (implementation == address(0)) owner = implementation_;
    }


    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        if (implementation == address(0)) revert noFallback();
        address i;
        assembly {
            i := sload(implementation.slot)
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), i, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
}
