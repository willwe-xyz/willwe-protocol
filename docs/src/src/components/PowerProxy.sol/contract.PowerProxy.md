# PowerProxy
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/components/PowerProxy.sol)

**Inherits:**
Receiver

**Authors:**
Michael Elliot <mike@makerdao.com>, Joshua Levine <joshua@makerdao.com>, Nick Johnson <arachnid@notdot.net>, OpenZeppelin OpenZeppelin.com
---------------------------------------, parseb.eth @ github.com/parseb

A simple authenticated proxy. A mashup of (MakerDAO) MulticallV2 and simple (OpenZeppelin) proxy.

*This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
be specified by overriding the virtual {_implementation} function.
Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
different contract through the {_delegate} function.
The success and return data of the delegated call will be returned back to the caller of the proxy.*


## State Variables
### owner

```solidity
address public owner;
```


### implementation

```solidity
address public implementation;
```


### isSignedHash
EIP 127 signature store


```solidity
mapping(bytes32 => bool) isSignedHash;
```


### allowedAuthType
Stores execution authorisation type.


```solidity
uint8 public immutable allowedAuthType;
```


## Functions
### constructor


```solidity
constructor(address proxyOwner_, uint8 consensusType_);
```

### tryAggregate


```solidity
function tryAggregate(bool requireSuccess, Call[] calldata calls) public returns (Result[] memory returnData);
```

### setImplementation


```solidity
function setImplementation(address implementation_) external;
```

### setOwner


```solidity
function setOwner(address owner_) external;
```

### setSignedHash


```solidity
function setSignedHash(bytes32 hash_) external;
```

### isValidSignature


```solidity
function isValidSignature(bytes32 hash_, bytes calldata _signature) external view returns (bytes4);
```

### fallback

*Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
function in the contract matches the call data.*


```solidity
fallback() external payable override receiverFallback;
```

## Errors
### noFallback

```solidity
error noFallback();
```

### NotOwner

```solidity
error NotOwner();
```

### Multicall2

```solidity
error Multicall2();
```

## Structs
### Call

```solidity
struct Call {
    address target;
    bytes callData;
    uint256 value;
}
```

### Result

```solidity
struct Result {
    bool success;
    bytes returnData;
}
```

