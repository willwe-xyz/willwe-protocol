// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {IExecution, SignatureQueue, NodeState, Movement} from "./IExecution.sol";

interface IFun is IERC1155, IExecution {
    // Root and Branch Management
    function spawnRootBranch(address fungible20_) external returns (uint256 fID);
    function spawnBranch(uint256 fid_) external returns (uint256 newID);
    function spawnBranchWithMembrane(
        uint256 fid_,
        address[] memory tokens_,
        uint256[] memory balances_,
        string memory meta_,
        uint256 inflationRate_
    ) external returns (uint256 newID);

    // Membership Functions
    function mintMembership(uint256 fid_) external;
    function membershipEnforce(address target, uint256 fid_) external returns (bool s);
    function isMember(address whoabout_, uint256 whereabout_) external view returns (bool);

    // Token Operations
    function mint(uint256 fid_, uint256 amount_) external;
    function mintPath(uint256 target_, uint256 amount_) external;
    function burn(uint256 fid_, uint256 amount_) external returns (uint256 topVal);
    function burnPath(uint256 target_, uint256 amount) external;
    function mintInflation(uint256 node) external returns (uint256 amount);

    // Signals and Control
    function sendSignal(uint256 targetNode_, uint256[] memory signals) external;
    function resignal(uint256 targetNode_, uint256[] memory signals, address originator) external;
    function initSelfControl() external returns (address controlingAgent);
    function setControl(address newController) external;
    function redistribute(uint256 nodeId_) external returns (uint256 distributedAmt);
    function redistributePath(uint256 nodeId_) external returns (uint256 distributedAmt);
    function taxPolicyPreference(address rootToken_, uint256 taxRate_) external;

    // Movement Management
    function startMovement(
        uint8 typeOfMovement,
        uint256 node,
        uint256 expiresInDays,
        address executingAccount,
        string memory description,
        bytes memory data
    ) external returns (bytes32 movementHash);

    // Endpoint Management
    function localizeEndpoint(address endpoint_, uint256 endpointParent_, address owner_) external;

    // View Functions
    function asRootValuation(uint256 target_, uint256 amount) external view returns (uint256 rAmt);
    function inParentDenomination(uint256 amt_, uint256 id_) external view returns (uint256);
    function getFidPath(uint256 fid_) external view returns (uint256[] memory fids);
    function getMembraneOf(uint256 fid_) external view returns (uint256);
    function allMembersOf(uint256 fid_) external view returns (address[] memory);
    function getChildrenOf(uint256 fid_) external view returns (uint256[] memory);
    function getParentOf(uint256 fid_) external view returns (uint256);
    function membershipID(uint256 fid_) external pure returns (uint256);
    function inflationOf(uint256 nodeId) external view returns (uint256);
    function totalSupply(uint256 nodeId) external view returns (uint256);
    function getUserNodeSignals(address signalOrigin, uint256 parentNodeId)
        external
        view
        returns (uint256[2][] memory);

    // Data Access
    function getNodeData(uint256 nodeId, address user) external view returns (NodeState memory);
    function getNodes(uint256[] memory nodeIds) external view returns (NodeState[] memory nodes);
    function getAllNodesForRoot(address rootAddress, address userIfAny)
        external
        view
        returns (NodeState[] memory nodes);

    // Utility Functions
    function toID(address x) external pure returns (uint256);
    function toAddress(uint256 x) external pure returns (address);
    function uri(uint256 id_) external view returns (string memory);
}
