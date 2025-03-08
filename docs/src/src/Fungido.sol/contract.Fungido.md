# Fungido
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/Fungido.sol)

**Inherits:**
ERC1155, [PureUtils](/src/components/PureUtils.sol/contract.PureUtils.md)

**Author:**
Bogdan A. | parseb


## State Variables
### INIT_TIME

```solidity
uint256 immutable INIT_TIME = block.timestamp;
```


### DEFAULT_INFLATION

```solidity
uint256 immutable DEFAULT_INFLATION = 1_000 gwei;
```


### DEFAULT_TAXREATE

```solidity
uint256 immutable DEFAULT_TAXREATE = 100_0;
```


### entityCount

```solidity
uint256 public entityCount;
```


### executionAddress

```solidity
address public executionAddress;
```


### Will

```solidity
address public Will;
```


### M

```solidity
IMembrane M;
```


### totalSupplyOf
stores the total supply of each id | id -> supply


```solidity
mapping(uint256 => uint256) totalSupplyOf;
```


### childrenOf
gets children of parent entity given its id | parent => [child...]


```solidity
mapping(uint256 => uint256[]) childrenOf;
```


### parentOf
parent of instance chain | is root if parent is 0


```solidity
mapping(uint256 => uint256) parentOf;
```


### inflSec
inflation per second | entityID -> [ inflationpersec | last modified | last minted ]


```solidity
mapping(uint256 => uint256[3]) inflSec;
```


### inUseMembraneId
membrane being used by entity | entityID ->  [ membrane id | last Timestamp]


```solidity
mapping(uint256 => uint256[2]) inUseMembraneId;
```


### members
members of node || user address -> user endpoints || root id -> all derrived subnodes ids


```solidity
mapping(uint256 => address[]) members;
```


### options
stores a users option for change and node state [ wanted value, lastExpressedAt ]


```solidity
mapping(bytes32 NodeXUserXValue => uint256[3] valueAtTime) public options;
```


### taxRate
tax rate on withdrawals as share in base root value token (default: 0.1%)


```solidity
mapping(address => uint256) taxRate;
```


### control

```solidity
address[2] public control;
```


### initControlAddress

```solidity
address initControlAddress;
```


### impersonatingAddress

```solidity
address impersonatingAddress;
```


### name

```solidity
string public name;
```


### symbol

```solidity
string public symbol;
```


### useBefore

```solidity
bool useBefore;
```


## Functions
### constructor


```solidity
constructor(address executionAddr, address membranes);
```

### setControl

sets address in control of fiscal policy

can chenge token specific tax rates, should be an endpoint

two step function


```solidity
function setControl(address newController) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newController`|`address`|address of new controller|


### initSelfControl


```solidity
function initSelfControl() external returns (address);
```

### spawnRootNode

spawns core Node for a token

acts as port for token value

nests all token specific contexts


```solidity
function spawnRootNode(address fungible20_) public virtual returns (uint256 fID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fungible20_`|`address`|address of ERC20 token|


### spawnNode

creates new context nested under a parent node id

agent spawning a new underlink needs to be a member in containing context


```solidity
function spawnNode(uint256 fid_) public virtual returns (uint256 newID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fid_`|`uint256`|context node id|


### spawnNodeWithMembrane

spawns Node with an enforceable membership mechanism and creates new membrane


```solidity
function spawnNodeWithMembrane(
    uint256 fid_,
    address[] memory tokens_,
    uint256[] memory balances_,
    string memory meta_,
    uint256 inflationRate_
) public virtual returns (uint256 newID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fid_`|`uint256`|context (parent) node|
|`tokens_`|`address[]`|array of token addresses for membrane conditions|
|`balances_`|`uint256[]`|array of required balances for each token|
|`meta_`|`string`|metadata string (e.g. IPFS hash) for membrane details|
|`inflationRate_`|`uint256`|rate for new Node token shares in gwei per second|


### mintMembership

mints membership to calling address if it satisfies membership conditions


```solidity
function mintMembership(uint256 fid_) public virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fid_`|`uint256`|node for which to mint membership|


### mint

mints amount of specified fid

requires an equal deposit of parent fid or root to be added to target reserve


```solidity
function mint(uint256 fid_, uint256 amount_) public virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fid_`|`uint256`|id to target for mint of kind|
|`amount_`|`uint256`|amout to be minted|


### mintPath

mints the specified amount of target fid

transfers the amount specified of erc 20 and mints all fids on path to target root


```solidity
function mintPath(uint256 target_, uint256 amount_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target_`|`uint256`|id to target for mint of kind|
|`amount_`|`uint256`|amout to be minted|


### burn

burn the amount of targeted node id


```solidity
function burn(uint256 fid_, uint256 amount_) public virtual returns (uint256 topVal);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fid_`|`uint256`|id of node|
|`amount_`|`uint256`|amount to burn|


### burnPath


```solidity
function burnPath(uint256 target_, uint256 amount) external;
```

### membershipEnforce


```solidity
function membershipEnforce(address target, uint256 fid_) public virtual returns (bool s);
```

### mintInflation

mints the inflation of a specific context token

increases ratio of reserve to context denomination


```solidity
function mintInflation(uint256 node) public virtual returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`node`|`uint256`|identifier of node context|


### _giveMembership


```solidity
function _giveMembership(address to, uint256 id) private;
```

### localizeEndpoint


```solidity
function localizeEndpoint(address endpoint_, uint256 endpointParent_, address owner_) external;
```

### _localizeNode


```solidity
function _localizeNode(uint256 newID, uint256 parentId) internal;
```

### taxPolicyPreference

default is 100_0 0.1%. custom range 1-100_00 basis points


```solidity
function taxPolicyPreference(address rootToken_, uint256 taxRate_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rootToken_`|`address`||
|`taxRate_`|`uint256`|share retained at full exit withdrawal expressed as basis points (default 0.01% or 100)|


### asRootValuation

calculates and returns the value of a number of context tokens in terms of its root reserve


```solidity
function asRootValuation(uint256 target_, uint256 amount) public view returns (uint256 rAmt);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target_`|`uint256`|target node and its context token|
|`amount`|`uint256`|how many of to price|


### inParentDenomination

calculates the value of a number of context tokens in terms of reserve token

reserve token is allways smaller


```solidity
function inParentDenomination(uint256 amt_, uint256 id_) public view returns (uint256 inParentVal);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amt_`|`uint256`|how many of to price|
|`id_`|`uint256`|target node by id and its context token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`inParentVal`|`uint256`|max price of inputs at current minted inflation|


### getFidPath

retrieves token path id array from root to target id


```solidity
function getFidPath(uint256 fid_) public view returns (uint256[] memory fids);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fid_`|`uint256`|target fid to trace path to from root|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fids`|`uint256[]`|lineage in chronologic order|


### _useAfterTokenTransfer


```solidity
function _useAfterTokenTransfer() internal view override returns (bool);
```

### _useBeforeTokenTransfer


```solidity
function _useBeforeTokenTransfer() internal view override returns (bool);
```

### _beforeTokenTransfer


```solidity
function _beforeTokenTransfer(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
) internal virtual override;
```

### _mint


```solidity
function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override;
```

### _burn


```solidity
function _burn(address from, uint256 id, uint256 amount) internal override;
```

### _msgSender


```solidity
function _msgSender() internal view virtual returns (address);
```

### toAddress


```solidity
function toAddress(uint256 x) public pure returns (address);
```

### toID


```solidity
function toID(address x) public pure returns (uint256);
```

### isMember

checks if provided address who is member in where id


```solidity
function isMember(address whoabout_, uint256 whereabout_) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`whoabout_`|`address`|you care about them dont you|
|`whereabout_`|`uint256`|you abouting about where exactly|


### getMembraneOf


```solidity
function getMembraneOf(uint256 fid_) public view returns (uint256);
```

### allMembersOf


```solidity
function allMembersOf(uint256 fid_) public view returns (address[] memory);
```

### getChildrenOf


```solidity
function getChildrenOf(uint256 fid_) public view returns (uint256[] memory);
```

### getParentOf


```solidity
function getParentOf(uint256 fid_) public view returns (uint256);
```

### membershipID


```solidity
function membershipID(uint256 fid_) public pure returns (uint256);
```

### inflationOf


```solidity
function inflationOf(uint256 nodeId) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(uint256 nodeId) external view returns (uint256);
```

### uri

*See [IERC1155MetadataURI-uri](/lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol/contract.ERC1155.md#uri).
This implementation returns the same URI for *all* token types. It relies
on the token type ID substitution mechanism
https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
Clients calling this function must replace the `\{id\}` substring with the
actual token type ID.*


```solidity
function uri(uint256 id_) public view virtual override returns (string memory);
```

### setApprovalForAll


```solidity
function setApprovalForAll(address operator, bool isApproved) public override;
```

### getNodeData

returns a node's data given its identifier


```solidity
function getNodeData(uint256 nodeId) public view returns (NodeState memory NodeData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeId`|`uint256`|node identifier|


### getNodes

Node identifier
Current inflation rate per second
Reserve balance - amount of tokens held in parent's reserve
Budget balance - amount of tokens held in node's own account
Root valuation of node's budget (denominated in root token)
Root valuation of node's reserve (denominated in root token)
Active membrane identifier
Redistribution eligibility rate from parent per second in root valuation
Timestamp of last redistribution
Balance of user
basicInfo[9];
Endpoint of user for node
basicInfo[10]
Membrane Metadata CID
Array of member addresses
Array of direct children node IDs
Path from root token to node ID (ancestors)


```solidity
function getNodes(uint256[] memory nodeIds) public view returns (NodeState[] memory nodes);
```

### getAllNodesForRoot




```solidity
function getAllNodesForRoot(address rootAddress, address userIfAny) external view returns (NodeState[] memory nodes);
```

### getChildParentEligibilityPerSec


```solidity
function getChildParentEligibilityPerSec(uint256 childId_, uint256 parentId_) public view returns (uint256);
```

### getUserNodeSignals

Returns the array containing signal info for each child node in given originator and parent context


```solidity
function getUserNodeSignals(address signalOrigin, uint256 parentNodeId)
    public
    view
    returns (uint256[2][] memory UserNodeSignals);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signalOrigin`|`address`|address of originator|
|`parentNodeId`|`uint256`|node id for which originator has expressed|


### getNodeDataWithUserSignals


```solidity
function getNodeDataWithUserSignals(uint256 nodeId, address user) public view returns (NodeState memory nodeData);
```

## Events
### SelfControlAtAddress

```solidity
event SelfControlAtAddress(address AgencyLocus);
```

### NewRootNode

```solidity
event NewRootNode(uint256 indexed rootNodeId);
```

### NewNode

```solidity
event NewNode(uint256 indexed newId, uint256 indexed parentId, address indexed creator);
```

## Errors
### UniniMembrane

```solidity
error UniniMembrane();
```

### BaseOrNonFungible

```solidity
error BaseOrNonFungible();
```

### StableRoot

```solidity
error StableRoot();
```

### AlreadyMember

```solidity
error AlreadyMember();
```

### NodeNotFound

```solidity
error NodeNotFound();
```

### Unqualified

```solidity
error Unqualified();
```

### MintE20TransferFailed

```solidity
error MintE20TransferFailed();
```

### BurnE20TransferFailed

```solidity
error BurnE20TransferFailed();
```

### InsufficientRootBalance

```solidity
error InsufficientRootBalance();
```

### UnregisteredFungible

```solidity
error UnregisteredFungible();
```

### EOA

```solidity
error EOA();
```

### RootExists

```solidity
error RootExists();
```

### NodeAlreadyExists

```solidity
error NodeAlreadyExists();
```

### UnsupportedTransfer

```solidity
error UnsupportedTransfer();
```

### NoMembership

```solidity
error NoMembership();
```

### NotMember

```solidity
error NotMember();
```

### MembershipOp

```solidity
error MembershipOp();
```

### No

```solidity
error No();
```

### ExecutionOnly

```solidity
error ExecutionOnly();
```

### CoreGasTransferFailed

```solidity
error CoreGasTransferFailed();
```

### NoControl

```solidity
error NoControl();
```

### Unautorised

```solidity
error Unautorised();
```

### SignalOverflow

```solidity
error SignalOverflow();
```

### InsufficientAmt

```solidity
error InsufficientAmt();
```

### IncompleteSign

```solidity
error IncompleteSign();
```

### isControled

```solidity
error isControled();
```

### Disabled

```solidity
error Disabled();
```

