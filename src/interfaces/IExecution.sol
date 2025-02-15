// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

enum SQState {
    None,
    Initialized,
    Valid,
    Executed,
    Stale
}

enum MovementType {
    Revert,
    AgentMajority,
    EnergeticMajority
}

struct Call {
    address target;
    bytes callData;
    uint256 value;
}

struct Movement {
    MovementType category;
    address initiatior;
    address exeAccount;
    uint256 viaNode;
    uint256 expiresAt;
    string description;
    bytes executedPayload;
}

struct LatentMovement {
    Movement movement;
    SignatureQueue signatureQueue;
}

struct SignatureQueue {
    SQState state;
    Movement Action;
    address[] Signers;
    bytes[] Sigs;
    bytes32 exeSig;
}

struct UserSignal {
    string[2][] MembraneInflation;
    string[] lastRedistSignal;
}

struct NodeState {
    string[11] basicInfo; // [nodeId, inflation, reserve, budget, rootValuationBudget, rootValuationReserve, membraneId, eligibilityPerSec, lastRedistributionTime, balanceOfUser [0 default], endpointOfUserForNode [address(0) defaul - no endpoint]]
    string membraneMeta; // Membrane Metadata CID
    address[] membersOfNode; // Array of member addresses
    string[] childrenNodes; // Array of children node IDs
    address[] movementEndpoints; // Array of node specific execution endpoints
    string[] rootPath; // Path from root to current node
    UserSignal[] signals; // Array of signals
}

interface IExecution {
    function createEndpointForOwner(address origin, uint256 nodeId_, address owner)
        external
        returns (address endpoint);

    function executeQueue(bytes32 SignatureQueueHash_) external returns (bool s);

    function submitSignatures(bytes32 sigHash, address[] memory signers, bytes[] memory signatures) external;

    function startMovement(
        address origin,
        uint8 typeOfMovement,
        uint256 node_,
        uint256 expiresInDays,
        address executingAccount,
        string memory description,
        bytes memory data
    ) external returns (bytes32 movementHash);

    function setWillWe(address WillWeImplementationAddress) external;

    /// View

    function isQueueValid(bytes32 sigHash) external view returns (bool);

    function FoundingAgent() external returns (address);

    function WillToken() external view returns (address);

    function getSigQueue(bytes32 hash_) external view returns (SignatureQueue memory);

    /// @notice retrieves the node or agent  that owns the execution account
    /// @param endpointAddress execution account for which to retrieve owner
    /// @dev in case of user-driven endpoints the returned value is uint160( address of endpoint creator )
    function endpointOwner(address endpointAddress) external view returns (uint256);

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);

    function hashMessage(Movement memory movement) external view returns (bytes32);

    function createInitWillWeEndpoint(uint256 nodeId_) external returns (address endpoint);

    function getLatentMovements(uint256 nodeId_) external view returns (LatentMovement[] memory latentMovements);

    //// cleanup functions

    function removeSignature(bytes32 sigHash_, uint256 index_, address who_) external;

    function removeLatentAction(bytes32 actionHash_, uint256 index) external;
}
