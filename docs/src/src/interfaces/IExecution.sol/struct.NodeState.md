# NodeState
[Git Source](https://github.com/parseb/willwe/blob/2224ac0edd2345ec0b06622d841db6de03281d90/src/interfaces/IExecution.sol)


```solidity
struct NodeState {
    string[11] basicInfo;
    string membraneMeta;
    address[] membersOfNode;
    string[] childrenNodes;
    string[] rootPath;
    UserSignal[] signals;
}
```

