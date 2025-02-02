# Membranes
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/Membranes.sol)

**Inherits:**
[IMembrane](/src/interfaces/IMembrane.sol/interface.IMembrane.md)

**Author:**
parseb (original), Assistant (refactored)


## State Variables
### membraneById

```solidity
mapping(uint256 => Membrane) membraneById;
```


### willWe

```solidity
IFun public willWe;
```


## Functions
### createMembrane

creates membrane. Used to control and define.

To be read and understood as: Givent this membrane, of each of the tokens_[x], the user needs at least balances_[x].


```solidity
function createMembrane(address[] memory tokens_, uint256[] memory balances_, string memory meta_)
    public
    virtual
    returns (uint256 id);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokens_`|`address[]`|ERC20 or ERC721 token addresses array. Each is used as a constituent item of the membrane and condition for|
|`balances_`|`uint256[]`|amounts required of each of tokens_. The order of required balances needs to map to token addresses.|
|`meta_`|`string`|anything you want. Preferably stable CID for reaching aditional metadata such as an IPFS hash of type string.|


### setInitWillWe


```solidity
function setInitWillWe() external;
```

### gCheck

checks if given address respects the conditions of the specified membrane


```solidity
function gCheck(address who_, uint256 membraneID_) public view returns (bool s);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`who_`|`address`||
|`membraneID_`|`uint256`||


### getMembraneById


```solidity
function getMembraneById(uint256 id_) public view returns (Membrane memory);
```

## Events
### WillWeSet

```solidity
event WillWeSet(address willWeAddress);
```

### MembraneCreated

```solidity
event MembraneCreated(uint256 indexed membraneId, string CID);
```

## Errors
### membraneNotFound

```solidity
error membraneNotFound();
```

### Membrane__EmptyFieldOnMembraneCreation

```solidity
error Membrane__EmptyFieldOnMembraneCreation();
```

### Membrane__UnauthorizedWillWeSet

```solidity
error Membrane__UnauthorizedWillWeSet();
```

