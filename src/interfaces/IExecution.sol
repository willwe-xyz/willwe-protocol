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

struct Movement {
    MovementType category;
    address initiatior;
    address exeAccount;
    uint256 viaNode;
    uint256 expiresAt;
    string description;
    bytes executedPayload;
}

struct SignatureQueue {
    SQState state;
    Movement Action;
    address[] Signers;
    bytes[] Sigs;
}


struct LatentMovement {
    Movement movement;
    SignatureQueue signatureQueue;
    bytes32 movementHash;
}

struct SignatureQueue {
    SQState state;
    Movement Action;
    address[] Signers;
    bytes[] Sigs;
}

struct UserSignal {
    string[2][] MembraneInflation;
    string[] lastRedistSignal;
}
struct Call {
    address target;
    bytes callData;
    uint256 value;
}
struct NodeState {
    string[12] basicInfo; // [nodeId, inflation, reserve, budget, rootValuationBudget, rootValuationReserve, membraneId, eligibilityPerSec, lastRedistributionTime, balanceOfUser [0 default], endpointOfUserForNode [address(0) defaul - no endpoint], total supply of node]
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

    //// @notice instantiates a new movement
    //// @param typeOfMovement 1 agent majority 2 value majority
    //// @param nodeId identifiable atomic entity doing the moving, must be owner of the executing account
    /// @param expiresInDays deadline for expiry now plus days
    /// @param executingAccount external address acting as execution environment for movement
    /// @param description description of movement or description CID
    /// @param data calldata for execution call or executive payload
    function startMovement(
        uint8 typeOfMovement,
        uint256 nodeId,
        uint256 expiresInDays,
        address executingAccount,
        string memory description,
        bytes memory data
    ) external returns (bytes32 movementHash);

    function setWillWe(address WillWeImplementationAddress) external;

    function removeSignature(bytes32 sigHash_, uint256 index_, address who_) external;

    function removeLatentAction(bytes32 actionHash_, uint256 index) external;

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

    function createInitWillWeEndpoint(uint256 nodeId_) external returns (address endpoint);

    function getLatentMovements(uint256 nodeId_) external view returns (LatentMovement[] memory latentMovements);

    function nextSalt() external view returns (bytes32);

    function hashMovement(Movement memory movement) external pure returns (bytes32);

    function getDigestToSign(Movement memory movement) external view returns (bytes32);

    function getEIP712MessageHash(bytes32 movementHash) external view returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function MOVEMENT_TYPEHASH() external view returns (bytes32);

    function EIP712_DOMAIN_TYPEHASH() external view returns (bytes32);
}
