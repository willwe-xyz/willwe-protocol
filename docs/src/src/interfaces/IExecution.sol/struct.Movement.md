# Movement
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/interfaces/IExecution.sol)


```solidity
struct Movement {
    MovementType category;
    address initiatior;
    address exeAccount;
    uint256 viaNode;
    uint256 expiresAt;
    bytes32 descriptionHash;
    bytes executedPayload;
}
```

