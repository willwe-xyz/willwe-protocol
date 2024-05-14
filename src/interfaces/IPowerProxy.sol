pragma solidity ^0.8.19;

/// @author parseb.eth @ github.com/parseb

interface IPowerProxy {
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

    /// @notice returns the address that is authorised to use this proxy.
    /// @notice default value is deployer
    function owner() external returns (address);
    function implementation() external returns (address);

    /// @notice see multicall V2
    function tryAggregate(bool requireSuccess, Call[] calldata calls) external returns (Result[] memory returnData);
    function setImplementation(address implementation_) external;
    function setOwner(address owner_) external;
}
