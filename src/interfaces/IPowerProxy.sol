pragma solidity ^0.8.19;

/// @author parseb.eth @ github.com/parseb

interface IPowerProxy {
    /// @notice Struct representing a call to be made in the tryAggregate function
    struct Call {
        address target;
        bytes callData;
    }

    /// @notice Struct representing the result of a call made in the tryAggregate function
    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Thrown when the fallback function is called but no implementation is set
    error noFallback();

    /// @notice Thrown when a function is called by an address that is not the owner
    error NotOwner();

    /// @notice Thrown when a call in the tryAggregate function fails and requireSuccess is true
    error Multicall2();

    /// @notice Returns the address that is authorized to use this proxy
    function owner() external view returns (address);

    /// @notice Returns the address of the implementation behind the proxy
    function implementation() external view returns (address);

    /// @notice Returns the execution authorization type
    function allowedAuthType() external view returns (uint8);

    /// @notice Executes a batch of calls and returns the results
    /// @param requireSuccess If true, the function will revert if any call fails
    /// @param calls The batch of calls to execute
    /// @return returnData The results of the calls
    function tryAggregate(bool requireSuccess, Call[] calldata calls) external returns (Result[] memory returnData);

    /// @notice Sets the address of the implementation behind the proxy
    /// @param implementation_ The address of the new implementation
    function setImplementation(address implementation_) external;

    /// @notice Sets the address that is authorized to use this proxy
    /// @param owner_ The address of the new owner
    function setOwner(address owner_) external;

    /// @notice Checks if a given hash is a valid signature
    /// @param hash_ The hash to check
    /// @param _signature The signature to check
    /// @return The magic value 0x1626ba7e if the hash is a valid signature, 0 otherwise
    function isValidSignature(bytes32 hash_, bytes calldata _signature) external view returns (bytes4);

    /// @notice Sets the validity of a given hash
    /// @param hash_ The hash to set the validity of
    function setSignedHash(bytes32 hash_) external;
}
