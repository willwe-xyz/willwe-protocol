# IPowerProxy
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/interfaces/IPowerProxy.sol)

**Author:**
parseb.eth @ github.com/parseb


## Functions
### owner

Returns the address that is authorized to use this proxy


```solidity
function owner() external view returns (address);
```

### implementation

Returns the address of the implementation behind the proxy


```solidity
function implementation() external view returns (address);
```

### allowedAuthType

Returns the execution authorization type


```solidity
function allowedAuthType() external view returns (uint8);
```

### tryAggregate

Executes a batch of calls and returns the results


```solidity
function tryAggregate(bool requireSuccess, Call[] calldata calls) external returns (Result[] memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requireSuccess`|`bool`|If true, the function will revert if any call fails|
|`calls`|`Call[]`|The batch of calls to execute|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnData`|`Result[]`|The results of the calls|


### setImplementation

Sets the address of the implementation behind the proxy


```solidity
function setImplementation(address implementation_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`implementation_`|`address`|The address of the new implementation|


### setOwner

Sets the address that is authorized to use this proxy


```solidity
function setOwner(address owner_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner_`|`address`|The address of the new owner|


### isValidSignature

Checks if a given hash is a valid signature


```solidity
function isValidSignature(bytes32 hash_, bytes calldata _signature) external view returns (bytes4);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`hash_`|`bytes32`|The hash to check|
|`_signature`|`bytes`|The signature to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|The magic value 0x1626ba7e if the hash is a valid signature, 0 otherwise|


### setSignedHash

Sets the validity of a given hash


```solidity
function setSignedHash(bytes32 hash_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`hash_`|`bytes32`|The hash to set the validity of|


## Errors
### noFallback
Thrown when the fallback function is called but no implementation is set


```solidity
error noFallback();
```

### NotOwner
Thrown when a function is called by an address that is not the owner


```solidity
error NotOwner();
```

### Multicall2
Thrown when a call in the tryAggregate function fails and requireSuccess is true


```solidity
error Multicall2();
```

## Structs
### Call
Struct representing a call to be made in the tryAggregate function


```solidity
struct Call {
    address target;
    bytes callData;
    uint256 value;
}
```

### Result
Struct representing the result of a call made in the tryAggregate function


```solidity
struct Result {
    bool success;
    bytes returnData;
}
```

