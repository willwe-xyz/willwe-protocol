# Fun
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/Fun.sol)

**Inherits:**
[Fungido](/src/Fungido.sol/contract.Fungido.md)

**Author:**
parseb


## Functions
### constructor


```solidity
constructor(address ExeAddr, address Membranes_) Fungido(ExeAddr, Membranes_);
```

### resignal


```solidity
function resignal(uint256 targetNode_, uint256[] memory signals, address originator) public virtual;
```

### _msgSender


```solidity
function _msgSender() internal view override returns (address);
```

### sendSignal


```solidity
function sendSignal(uint256 targetNode_, uint256[] memory signals) public virtual;
```

### _handleSpecialSignals


```solidity
function _handleSpecialSignals(
    uint256 targetNode_,
    uint256 user,
    uint256 signal,
    uint256 index,
    uint256 balanceOfSender,
    bytes32 userkey
) private;
```

### _handleMembraneSignal


```solidity
function _handleMembraneSignal(
    uint256 targetNode_,
    bytes32 userKey,
    bytes32 nodeKey,
    uint256 signal,
    uint256 balanceOfSender
) private;
```

### _handleInflationSignal


```solidity
function _handleInflationSignal(
    uint256 targetNode_,
    bytes32 userKey,
    bytes32 nodeKey,
    uint256 signal,
    uint256 balanceOfSender
) private;
```

### _handleRegularSignals


```solidity
function _handleRegularSignals(
    uint256 targetNode_,
    uint256 user,
    uint256 signal,
    uint256 index,
    uint256 balanceOfSender,
    uint256 signalsLength,
    uint256[] memory children
) private;
```

### _updateSignalOption


```solidity
function _updateSignalOption(
    uint256 targetNode_,
    bytes32 userKey,
    bytes32 nodeKey,
    uint256 signal,
    uint256 balanceOfSender
) private;
```

### _updateChildParentEligibility


```solidity
function _updateChildParentEligibility(uint256 childId, uint256 parentId, bytes32 userTargetedPreference) private;
```

### redistribute

redistributes eligible acummulated inflationary flows


```solidity
function redistribute(uint256 nodeId_) public returns (uint256 distributedAmt);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeId_`|`uint256`|redistribution target group|


### redistributePath

redistributes eligible amounts to all nodes on target path and mints inflation for target


```solidity
function redistributePath(uint256 nodeId_) external returns (uint256 distributedAmt);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeId_`|`uint256`|target node to actualize path to and mint inflation for|


### startMovement


```solidity
function startMovement(
    uint8 typeOfMovement,
    uint256 node,
    uint256 expiresInDays,
    address executingAccount,
    bytes32 descriptionHash,
    bytes memory data
) external returns (bytes32 movementHash);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`typeOfMovement`|`uint8`||
|`node`|`uint256`||
|`expiresInDays`|`uint256`|deadline for expiry now plus days|
|`executingAccount`|`address`|external address acting as execution environment for movement|
|`descriptionHash`|`bytes32`|hash of descrptive metadata|
|`data`|`bytes`|calldata for execution call or executive payload|


### createEndpointForOwner

creates an external endpoint for an agent in node context

node owner can be external


```solidity
function createEndpointForOwner(uint256 nodeId_, address owner) external returns (address endpoint);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeId_`|`uint256`|id of context node|
|`owner`|`address`|address of agent that will control the endpoint|


### executeQueue

executes the signature queue identified by its hash if signing requirements


```solidity
function executeQueue(bytes32 SignatureQueueHash_) external returns (bool s);
```

### submitSignatures

submits a list of signatures to a specific movement queue


```solidity
function submitSignatures(bytes32 sigHash, address[] memory signers, bytes[] memory signatures) external;
```

### removeSignature


```solidity
function removeSignature(bytes32 sigHash_, uint256 index_) external;
```

### getSigQueue


```solidity
function getSigQueue(bytes32 hash_) public view returns (SignatureQueue memory);
```

### isQueueValid


```solidity
function isQueueValid(bytes32 sigHash) public view returns (bool);
```

### isValidSignature


```solidity
function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
```

### calculateUserTargetedPreferenceAmount


```solidity
function calculateUserTargetedPreferenceAmount(uint256 childId, uint256 parentId, uint256 signal, address user)
    public
    view
    returns (uint256);
```

## Events
### NewMovement

```solidity
event NewMovement(uint256 indexed nodeId, bytes32 movementHash, bytes32 descriptionHash);
```

### InflationRateChanged

```solidity
event InflationRateChanged(uint256 indexed nodeId, uint256 oldInflationRate, uint256 newInflationRate);
```

### MembraneChanged

```solidity
event MembraneChanged(uint256 indexed nodeId, uint256 previousMembrane, uint256 newMembrane);
```

### Signaled

```solidity
event Signaled(uint256 indexed nodeId, address sender, address origin);
```

### ConfigSignal

```solidity
event ConfigSignal(uint256 indexed nodeId, bytes32 expressedOption);
```

## Errors
### BadLen

```solidity
error BadLen();
```

### Noise

```solidity
error Noise();
```

### NoSoup

```solidity
error NoSoup();
```

### MembraneNotFound

```solidity
error MembraneNotFound();
```

### RootNodeOrNone

```solidity
error RootNodeOrNone();
```

### NoiseNotVoice

```solidity
error NoiseNotVoice();
```

### TargetIsRoot

```solidity
error TargetIsRoot();
```

### PathTooShort

```solidity
error PathTooShort();
```

### ResignalMismatch

```solidity
error ResignalMismatch();
```

### NoTimeDelta

```solidity
error NoTimeDelta();
```

### CannotSkip

```solidity
error CannotSkip();
```

