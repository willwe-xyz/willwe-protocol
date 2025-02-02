# EIP712
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/info/EIP712.sol)


## State Variables
### DOMAIN_SEPARATOR

```solidity
bytes32 internal DOMAIN_SEPARATOR;
```


### SALT

```solidity
bytes32 internal immutable SALT;
```


## Functions
### constructor


```solidity
constructor();
```

### hashDomain


```solidity
function hashDomain(EIP712Domain memory domain) public pure returns (bytes32);
```

### hashMessage


```solidity
function hashMessage(Movement memory movement) public pure returns (bytes32);
```

### verifyMessage


```solidity
function verifyMessage(Movement memory movement, uint8 v, bytes32 r, bytes32 s, address expectedAddress)
    public
    view
    returns (bool);
```

