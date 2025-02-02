# WillWe
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/WillWe.sol)

**Inherits:**
[Fun](/src/Fun.sol/contract.Fun.md)

**Author:**
parseb

Experimental. Do not use.


## Functions
### constructor


```solidity
constructor(address Execution, address Membrane) Fun(Execution, Membrane);
```

### spawnBranch


```solidity
function spawnBranch(uint256 fid_) public virtual override returns (uint256 newID);
```

### mintMembership


```solidity
function mintMembership(uint256 fid_) public virtual override;
```

### mint


```solidity
function mint(uint256 fid_, uint256 amount_) public virtual override;
```

### burn


```solidity
function burn(uint256 fid_, uint256 amount_) public virtual override returns (uint256 topVal);
```

### mintInflation


```solidity
function mintInflation(uint256 node) public virtual override returns (uint256 amount);
```

## Events
### BranchSpawned

```solidity
event BranchSpawned(uint256 indexed parentId, uint256 indexed newBranchId, address indexed creator);
```

### MembershipMinted

```solidity
event MembershipMinted(uint256 indexed branchId, address indexed member);
```

### TokensMinted

```solidity
event TokensMinted(uint256 indexed branchId, address indexed minter, uint256 amount);
```

### TokensBurned

```solidity
event TokensBurned(uint256 indexed branchId, address indexed burner, uint256 amount);
```

### InflationMinted

```solidity
event InflationMinted(uint256 indexed branchId, uint256 amount);
```

### SignalSent

```solidity
event SignalSent(uint256 indexed branchId, address indexed sender, uint256[] signals);
```

