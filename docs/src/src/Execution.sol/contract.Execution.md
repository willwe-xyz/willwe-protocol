# Execution
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/Execution.sol)

**Inherits:**
[EIP712](/src/info/EIP712.sol/contract.EIP712.md), Receiver

**Author:**
parseb


## State Variables
### WillToken

```solidity
address public WillToken;
```


### WillWe

```solidity
IFun public WillWe;
```


### EIP1271_MAGICVALUE

```solidity
bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;
```


### EIP1271_MAGIC_VALUE_LEGACY

```solidity
bytes4 internal constant EIP1271_MAGIC_VALUE_LEGACY = 0x20c13b0b;
```


### EIP712_DOMAIN_TYPEHASH

```solidity
bytes32 public constant EIP712_DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
```


### MOVEMENT_TYPEHASH

```solidity
bytes32 public constant MOVEMENT_TYPEHASH = keccak256(
    "Movement(uint8 category,address initiatior,address exeAccount,uint256 viaNode,uint256 expiresAt,bytes32 descriptionHash,bytes executedPayload)"
);
```


### getSigQueueByHash
signature by hash


```solidity
mapping(bytes32 hash => SignatureQueue SigQueue) getSigQueueByHash;
```


### latentActions
initialized actions from node [node -> latentActionsOfNode[] | [0] valid start index, prevs. 0]


```solidity
mapping(uint256 => bytes32[]) latentActions;
```


### engineOwner
stores node that owns a particular execution engine


```solidity
mapping(address exeAccount => uint256 endpointOwner) engineOwner;
```


### hasEndpointOrInteraction
any one agent is allowed to have only one endpoint

stores agent signatures to prevent double signing  | ( uint256(hash) - uint256(_msgSender()  ) - signer can be simple or composed agent


```solidity
mapping(uint256 agentPlusNode => bool) hasEndpointOrInteraction;
```


## Functions
### constructor


```solidity
constructor(address WillToken_);
```

### setWillWe


```solidity
function setWillWe(address implementation) external;
```

### startMovement


```solidity
function startMovement(
    address origin,
    uint8 typeOfMovement,
    uint256 nodeId,
    uint256 expiresInDays,
    address executingAccount,
    bytes32 descriptionHash,
    bytes memory data
) external virtual returns (bytes32 movementHash);
```

### executeQueue


```solidity
function executeQueue(bytes32 queueHash) public virtual returns (bool success);
```

### submitSignatures


```solidity
function submitSignatures(bytes32 queueHash, address[] memory signers, bytes[] memory signatures) external;
```

### removeSignature


```solidity
function removeSignature(bytes32 queueHash, uint256 index, address signer) external;
```

### removeLatentAction


```solidity
function removeLatentAction(bytes32 actionHash, uint256 index) external;
```

### createEndpointForOwner


```solidity
function createEndpointForOwner(address origin, uint256 nodeId, address owner) external returns (address endpoint);
```

### createInitWillWeEndpoint


```solidity
function createInitWillWeEndpoint(uint256 nodeId_) external returns (address endpoint);
```

### createNodeEndpoint


```solidity
function createNodeEndpoint(uint256 nodeId_, uint8 consensusType_) private returns (address endpoint);
```

### spawnNodeEndpoint


```solidity
function spawnNodeEndpoint(address proxyOwner_, uint8 authType) private returns (address);
```

### validateQueue


```solidity
function validateQueue(bytes32 sigHash) internal returns (SignatureQueue memory SQM);
```

### isQueueValid


```solidity
function isQueueValid(bytes32 sigHash) public view returns (bool);
```

### isValidSignature


```solidity
function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4);
```

### endpointOwner

retrieves the node or agent that owns the execution account

*in case of user-driven endpoints the returned value is uint160(address of endpoint creator)*


```solidity
function endpointOwner(address endpointAddress) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`endpointAddress`|`address`|execution account for which to retrieve owner|


### getSigQueue


```solidity
function getSigQueue(bytes32 hash_) public view returns (SignatureQueue memory);
```

### hashMovement


```solidity
function hashMovement(Movement memory movement) public pure returns (bytes32);
```

### splitSignature


```solidity
function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s);
```

## Events
### NewMovementCreated
events


```solidity
event NewMovementCreated(bytes32 indexed movementHash, uint256 indexed nodeId);
```

### EndpointCreatedForAgent

```solidity
event EndpointCreatedForAgent(uint256 indexed nodeId, address endpoint, address agent);
```

### WillWeSet

```solidity
event WillWeSet(address implementation);
```

### NewSignaturesSubmitted

```solidity
event NewSignaturesSubmitted(bytes32 indexed queueHash);
```

### QueueExecuted

```solidity
event QueueExecuted(uint256 indexed nodeId, bytes32 indexed queueHash);
```

### SignatureRemoved

```solidity
event SignatureRemoved(uint256 indexed nodeId, bytes32 indexed queueHash, address signer);
```

### LatentActionRemoved

```solidity
event LatentActionRemoved(uint256 indexed nodeId, bytes32 indexed actionHash, uint256 index);
```

## Errors
### UninitQueue
errors


```solidity
error UninitQueue();
```

### ExpiredMovement

```solidity
error ExpiredMovement();
```

### InvalidQueue

```solidity
error InvalidQueue();
```

### EmptyUnallowed

```solidity
error EmptyUnallowed();
```

### NotNodeMember

```solidity
error NotNodeMember();
```

### AlreadyInitialized

```solidity
error AlreadyInitialized();
```

### UnavailableState

```solidity
error UnavailableState();
```

### ExpiredQueue

```solidity
error ExpiredQueue();
```

### NotExeAccOwner

```solidity
error NotExeAccOwner();
```

### AlreadyHasEndpoint

```solidity
error AlreadyHasEndpoint();
```

### NoMembersForNode

```solidity
error NoMembersForNode();
```

### NoMovementType

```solidity
error NoMovementType();
```

### AlreadySigned

```solidity
error AlreadySigned();
```

### LenErr

```solidity
error LenErr();
```

### AlreadyInit

```solidity
error AlreadyInit();
```

### OnlyWillWe

```solidity
error OnlyWillWe();
```

### NoSignatures

```solidity
error NoSignatures();
```

### EXEC_SQInvalid

```solidity
error EXEC_SQInvalid();
```

### EXEC_NoType

```solidity
error EXEC_NoType();
```

### EXEC_NoDescription

```solidity
error EXEC_NoDescription();
```

### EXEC_ZeroLen

```solidity
error EXEC_ZeroLen();
```

### EXEC_A0sig

```solidity
error EXEC_A0sig();
```

### EXEC_OnlyMore

```solidity
error EXEC_OnlyMore();
```

### EXEC_OnlySigner

```solidity
error EXEC_OnlySigner();
```

### EXEC_exeQFail

```solidity
error EXEC_exeQFail();
```

### EXEC_InProgress

```solidity
error EXEC_InProgress();
```

### EXEC_ActionIndexMismatch

```solidity
error EXEC_ActionIndexMismatch();
```

### EXEC_BadOwnerOrAuthType

```solidity
error EXEC_BadOwnerOrAuthType();
```

