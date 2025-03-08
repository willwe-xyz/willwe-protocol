# IFun
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/interfaces/IFun.sol)

**Inherits:**
IERC1155, [IExecution](/src/interfaces/IExecution.sol/interface.IExecution.md)


## Functions
### spawnRootNode


```solidity
function spawnRootNode(address fungible20_) external returns (uint256 fID);
```

### spawnNode


```solidity
function spawnNode(uint256 fid_) external returns (uint256 newID);
```

### spawnNodeWithMembrane


```solidity
function spawnNodeWithMembrane(uint256 fid_, uint256 membraneID_) external returns (uint256 newID);
```

### mintMembership


```solidity
function mintMembership(uint256 fid_, address to_) external returns (uint256 mID);
```

### membershipEnforce


```solidity
function membershipEnforce(address target, uint256 fid_) external returns (bool s);
```

### burn


```solidity
function burn(uint256 fid_, uint256 amount_) external;
```

### allMembersOf


```solidity
function allMembersOf(uint256 fid_) external view returns (address[] memory);
```

### mint


```solidity
function mint(uint256 fid_, uint256 amount_) external;
```

### toID


```solidity
function toID(address x) external view returns (uint256);
```

### toAddress


```solidity
function toAddress(uint256 x) external view returns (address);
```

### isMember


```solidity
function isMember(address whoabout_, uint256 whereabout_) external view returns (bool);
```

### getInUseMemberaneID


```solidity
function getInUseMemberaneID(uint256 fid_) external view returns (uint256 membraneID_);
```

### getMembraneOf


```solidity
function getMembraneOf(uint256 fid_) external view returns (uint256);
```

### getChildrenOf


```solidity
function getChildrenOf(uint256 fid_) external view returns (uint256[] memory);
```

### getParentOf


```solidity
function getParentOf(uint256 fid_) external view returns (uint256);
```

### membershipID


```solidity
function membershipID(uint256 fid_) external pure returns (uint256);
```

### getRootId


```solidity
function getRootId(uint256 fid_) external view returns (uint256);
```

### getRootToken


```solidity
function getRootToken(uint256 fid_) external view returns (address);
```

### fungo


```solidity
function fungo() external returns (address);
```

### createEndpointForOwner


```solidity
function createEndpointForOwner(uint256 nodeId_, address owner) external returns (address endpoint);
```

### localizeEndpoint


```solidity
function localizeEndpoint(address endpointAddress, uint256 endpointParent_, address endpointOwner_) external;
```

### getSigQueue


```solidity
function getSigQueue(bytes32 hash_) external view returns (SignatureQueue memory);
```

### totalSupply


```solidity
function totalSupply(uint256 nodeId) external view returns (uint256);
```

### executionEngineAddress


```solidity
function executionEngineAddress() external view returns (address);
```

### rule


```solidity
function rule() external;
```

### Will


```solidity
function Will() external view returns (address);
```

### getUserInteractions


```solidity
function getUserInteractions(address user_) external view returns (uint256[][2] memory);
```

### removeSignature


```solidity
function removeSignature(bytes32 sigHash_, uint256 index_) external;
```

### inParentDenomination


```solidity
function inParentDenomination(uint256 amt_, uint256 id_) external view returns (uint256);
```

### getFidPath


```solidity
function getFidPath(uint256 fid_) external view returns (uint256[] memory fids);
```

### burnPath


```solidity
function burnPath(uint256 target_, uint256 amount) external;
```

### mintPath


```solidity
function mintPath(uint256 target_, uint256 amount) external;
```

### sendSignal


```solidity
function sendSignal(uint256 targetNode_, uint256[] memory signals) external;
```

### initSelfControl


```solidity
function initSelfControl() external returns (address controlingAgent);
```

### getNodeData


```solidity
function getNodeData(uint256 n) external view returns (NodeState memory N);
```

### getNodes


```solidity
function getNodes(uint256[] memory nodeIds) external view returns (NodeState[] memory nodes);
```

### getAllNodesForRoot


```solidity
function getAllNodesForRoot(address rootAddress, address userIfAny) external view returns (NodeState[] memory nodes);
```

