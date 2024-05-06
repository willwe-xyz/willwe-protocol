pragma solidity ^0.8.20;

/// @author parseb.eth @ github.com/parseb

interface  IPowerProxy {

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
    
    /// @notice returns the address that is authorised to use this proxy.
    /// @notice default value is deployer
    function owner() external returns (address);

    /// @notice see multicall V2
    function tryAggregate(bool requireSuccess, Call[] calldata calls) public returns (Result[] memory returnData);
    function setImplOrOwner(address implementation_) external;




}
