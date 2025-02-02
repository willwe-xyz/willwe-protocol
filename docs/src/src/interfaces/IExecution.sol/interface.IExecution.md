# IExecution
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/interfaces/IExecution.sol)


## Functions
### createEndpointForOwner


```solidity
function createEndpointForOwner(address origin, uint256 nodeId_, address owner) external returns (address endpoint);
```

### executeQueue


```solidity
function executeQueue(bytes32 SignatureQueueHash_) external returns (bool s);
```

### submitSignatures


```solidity
function submitSignatures(bytes32 sigHash, address[] memory signers, bytes[] memory signatures) external;
```

### startMovement


```solidity
function startMovement(
    address origin,
    uint8 typeOfMovement,
    uint256 node_,
    uint256 expiresInDays,
    address executingAccount,
    bytes32 descriptionHash,
    bytes memory data
) external returns (bytes32 movementHash);
```

### setWillWe


```solidity
function setWillWe(address WillWeImplementationAddress) external;
```

### isQueueValid

View


```solidity
function isQueueValid(bytes32 sigHash) external view returns (bool);
```

### FoundingAgent


```solidity
function FoundingAgent() external returns (address);
```

### WillToken


```solidity
function WillToken() external view returns (address);
```

### getSigQueue


```solidity
function getSigQueue(bytes32 hash_) external view returns (SignatureQueue memory);
```

### endpointOwner

retrieves the node or agent  that owns the execution account

*in case of user-driven endpoints the returned value is uint160( address of endpoint creator )*


```solidity
function endpointOwner(address endpointAddress) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`endpointAddress`|`address`|execution account for which to retrieve owner|


### isValidSignature


```solidity
function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
```

### hashMessage


```solidity
function hashMessage(Movement memory movement) external view returns (bytes32);
```

### createInitWillWeEndpoint


```solidity
function createInitWillWeEndpoint(uint256 nodeId_) external returns (address endpoint);
```

### removeSignature


```solidity
function removeSignature(bytes32 sigHash_, uint256 index_, address who_) external;
```

### removeLatentAction


```solidity
function removeLatentAction(bytes32 actionHash_, uint256 index) external;
```

