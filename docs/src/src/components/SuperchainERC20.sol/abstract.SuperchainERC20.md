# SuperchainERC20
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/components/SuperchainERC20.sol)

**Inherits:**
ISuperchainERC20Extensions, ISuperchainERC20Errors, ERC20

SuperchainERC20 is a standard extension of the base ERC20 token contract that unifies ERC20 token
bridging to make it fungible across the Superchain. It builds on top of the L2ToL2CrossDomainMessenger for
both replay protection and domain binding.


## State Variables
### MESSENGER
Address of the L2ToL2CrossDomainMessenger Predeploy.


```solidity
address internal constant MESSENGER = Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER;
```


## Functions
### sendERC20

Sends tokens to some target address on another chain.


```solidity
function sendERC20(address _to, uint256 _amount, uint256 _chainId) external virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|     Address to send tokens to.|
|`_amount`|`uint256`| Amount of tokens to send.|
|`_chainId`|`uint256`|Chain ID of the destination chain.|


### relayERC20

Relays tokens received from another chain.


```solidity
function relayERC20(address _from, address _to, uint256 _amount) external virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|  Address of the msg.sender of sendERC20 on the source chain.|
|`_to`|`address`|    Address to relay tokens to.|
|`_amount`|`uint256`|Amount of tokens to relay.|


