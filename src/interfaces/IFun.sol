// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

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
}

struct Movement {
    MovementType category;
    /// proposer
    address initiatior;
    /// safe or similar execution environment
    address exeAccount;
    /// fid
    uint256 viaNode;
    /// signature expires - skip if expired
    uint256 expiresAt;
    bytes32 descriptionHash;
    /// calldata
    bytes executedPayload;
}

/// human view

struct SignatureQueue {
    SQState state;
    Movement Action;
    address[] Signers;
    bytes[] Sigs;
    bytes32 exeSig;
}

struct NodeState {
    uint256 nodeId;
    uint256 inflation;
    uint256 balanceAnchor;
    uint256 balanceBudget;
    uint256 membraneId;
    uint256 lastMinted;
    uint256 inflPerSec;
    address[] membersOfNode;
    uint256[] childrenNodes;
}

interface IFun is IERC1155 {
    function spawnRootBranch(address fungible20_) external returns (uint256 fID);

    function spawnBranch(uint256 fid_) external returns (uint256 newID);

    function spawnBranchWithMembrane(uint256 fid_, uint256 membraneID_) external returns (uint256 newID);

    function mintMembership(uint256 fid_, address to_) external returns (uint256 mID);

    function membershipEnforce(address target, uint256 fid_) external returns (bool s);
    function burn(uint256 fid_, uint256 amount_) external;
    function allMembersOf(uint256 fid_) external view returns (address[] memory);
    function mint(uint256 fid_, uint256 amount_) external;
    function toID(address x) external view returns (uint256);
    function toAddress(uint256 x) external view returns (address);
    function isMember(address whoabout_, uint256 whereabout_) external view returns (bool);
    function getInUseMemberaneID(uint256 fid_) external view returns (uint256 membraneID_);
    function getMembraneOf(uint256 fid_) external view returns (uint256);
    function getChildrenOf(uint256 fid_) external view returns (uint256[] memory);
    function getParentOf(uint256 fid_) external view returns (uint256);
    function membershipID(uint256 fid_) external pure returns (uint256);
    function getRootId(uint256 fid_) external view returns (uint256);
    function getRootToken(uint256 fid_) external view returns (address);
    function fungo() external returns (address);
    function createEndpointForOwner(uint256 nodeId_, address owner) external returns (address endpoint);
    function localizeEndpoint(address endpointAddress, uint256 endpointParent_, address endpointOwner_) external;
    function getSigQueue(bytes32 hash_) external view returns (SignatureQueue memory);
    function totalSupply(uint256 nodeId) external view returns (uint256);
    function executionEngineAddress() external view returns (address);
    function rule() external;
    function RVT() external view returns (address);
    function getUserInteractions(address user_) external view returns (uint256[][2] memory);
    function getInteractionDataOf(address user_)
        external
        view
        returns (uint256[][2] memory activeBalances, NodeState[] memory);
}
