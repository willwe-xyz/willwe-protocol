// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {Fungido} from "./Fungido.sol";
import {IExecution, SignatureQueue, Call} from "./interfaces/IExecution.sol";

/////////////////////////////////////////
/// @title Fun
/// @author parseb
///////////////////////////////////////////////

contract Fun is Fungido {
    constructor(address ExeAddr, address Membranes_) Fungido(ExeAddr, Membranes_) {
        executionAddress = ExeAddr;
        IExecution(ExeAddr).setWillWe(address(this));
    }

    // Remove unused errors
    error BadLen();
    error Noise();
    error NoSoup();
    error MembraneNotFound();
    error RootNodeOrNone();

    event NewMovement(uint256 indexed nodeId, bytes32 movementHash, bytes32 descriptionHash);

    function sendSignal(uint256 targetNode_, uint256[] memory signals) public virtual {
        if (parentOf[targetNode_] == targetNode_ || !isMember(msg.sender, targetNode_)) revert();
        if (balanceOf(msg.sender, targetNode_) < totalSupplyOf[targetNode_] / 100_00) revert();

        mintInflation(targetNode_);

        uint256 user = toID(msg.sender);
        uint256 balanceOfSender = balanceOf(msg.sender, targetNode_);
        uint256 sigSum;

        for (uint256 i; i < signals.length; ++i) {
            if (i <= 1) {
                _handleSpecialSignals(targetNode_, user, signals[i], i, balanceOfSender);
            } else {
                _handleRegularSignals(targetNode_, user, signals[i], i, balanceOfSender, signals.length);
                sigSum += signals[i];
            }
        }
        if (sigSum != 0 && sigSum != 100_00) revert IncompleteSign();
    }

    function _handleSpecialSignals(
        uint256 targetNode_,
        uint256 user,
        uint256 signal,
        uint256 index,
        uint256 balanceOfSender
    ) private {
        if (signal == 0) return;
        bytes32 userKey = keccak256(abi.encodePacked(targetNode_, user, signal));
        bytes32 nodeKey = keccak256(abi.encodePacked(targetNode_, signal));

        if (index == 0) {
            _handleMembraneSignal(targetNode_, userKey, nodeKey, signal, balanceOfSender);
        } else {
            _handleInflationSignal(targetNode_, userKey, nodeKey, signal, balanceOfSender);
        }
    }

    function _handleMembraneSignal(
        uint256 targetNode_,
        bytes32 userKey,
        bytes32 nodeKey,
        uint256 signal,
        uint256 balanceOfSender
    ) private {
        if (signal < type(uint160).max || M.getMembraneById(signal).tokens.length == 0) revert MembraneNotFound();
        _updateSignalOption(targetNode_, userKey, nodeKey, signal, balanceOfSender);
        if (options[nodeKey][0] * 2 > totalSupplyOf[targetNode_]) {
            inUseMembraneId[targetNode_] = [signal, block.timestamp];
        }
    }

    function _handleInflationSignal(
        uint256 targetNode_,
        bytes32 userKey,
        bytes32 nodeKey,
        uint256 signal,
        uint256 balanceOfSender
    ) private {
        _updateSignalOption(targetNode_, userKey, nodeKey, signal, balanceOfSender);
        if (options[nodeKey][0] * 2 > totalSupplyOf[targetNode_]) {
            inflSec[targetNode_] = [signal * 1 gwei, block.timestamp, inflSec[targetNode_][2]];
        }
    }

    function _handleRegularSignals(
        uint256 targetNode_,
        uint256 user,
        uint256 signal,
        uint256 index,
        uint256 balanceOfSender,
        uint256 signalsLength
    ) private {
        uint256[] memory children = childrenOf[targetNode_];
        if (children.length != (signalsLength - 2)) revert BadLen();

        bytes32 userTargetedPreference = keccak256(abi.encodePacked(user, targetNode_, children[index - 2]));
        if (signal > 100_00 && options[userTargetedPreference][0] == 0) return;

        if (options[userTargetedPreference][0] != signal) {
            options[userTargetedPreference] = [signal, block.timestamp];
            redistribute(children[index - 2]);
            _updateChildParentEligibility(children[index - 2], targetNode_, userTargetedPreference, balanceOfSender);
        }
    }

    function _updateSignalOption(
        uint256 targetNode_,
        bytes32 userKey,
        bytes32 nodeKey,
        uint256 signal,
        uint256 balanceOfSender
    ) private {
        if (options[userKey][1] > 0 && (inUseMembraneId[targetNode_][1] < options[userKey][1])) {
            options[nodeKey][0] -= options[userKey][0];
        }
        options[userKey] = [signal, block.timestamp];
        options[nodeKey][0] += balanceOfSender;
    }

    function _updateChildParentEligibility(
        uint256 childId,
        uint256 parentId,
        bytes32 userTargetedPreference,
        uint256 balanceOfSender
    ) private {
        bytes32 childParentEligibilityPerSec = keccak256(abi.encodePacked(childId, parentId));
        options[childParentEligibilityPerSec][0] = options[childParentEligibilityPerSec][0]
            > options[userTargetedPreference][1]
            ? options[childParentEligibilityPerSec][0] - options[userTargetedPreference][1]
            : 0;
        options[userTargetedPreference][1] = (balanceOfSender * 1 ether / totalSupplyOf[parentId])
            * (options[userTargetedPreference][0] * inflSec[parentId][0] / 100_00) / 1 ether;
        options[childParentEligibilityPerSec][0] += options[userTargetedPreference][1];
        options[childParentEligibilityPerSec][1] = block.timestamp;
    }

    //// @notice redistributes eligible acummulated inflationary flows
    /// @param nodeId_ redistribution target group
    function redistribute(uint256 nodeId_) public returns (uint256 distributedAmt) {
        uint256 parent = parentOf[nodeId_];
        if (parent == 0) revert NoSoup();
        mintInflation(parentOf[nodeId_]);

        bytes32 childParentEligibility = keccak256((abi.encodePacked(nodeId_, parent)));
        distributedAmt = options[childParentEligibility][0] * (block.timestamp - options[childParentEligibility][1]);
        options[childParentEligibility][0] = block.timestamp;

        _safeTransfer(toAddress(parent), toAddress(nodeId_), parent, distributedAmt, abi.encodePacked("redistribution"));
    }

    /////////// External

    //// @notice instantiates a new movement
    //// @param typeOfMovement 1 agent majority 2 value majority
    //// @param node identifiable atomic entity doing the moving, must be owner of the executing account
    /// @param expiresInDays deadline for expiry now plus days
    /// @param executingAccount external address acting as execution environment for movement
    /// @param descriptionHash hash of descrptive metadata
    /// @param data calldata for execution call or executive payload
    function startMovement(
        uint256 typeOfMovement,
        uint256 node,
        uint256 expiresInDays,
        address executingAccount,
        bytes32 descriptionHash,
        bytes memory data
    ) external returns (bytes32 movementHash) {
        movementHash = IExecution(executionAddress).startMovement(
            _msgSender(), typeOfMovement, node, expiresInDays, executingAccount, descriptionHash, data
        );
        emit NewMovement(node, movementHash, descriptionHash);
    }

    /// @notice creates an external endpoint for an agent in node context
    /// @notice node owner can be external
    /// @param nodeId_ id of context node
    /// @param owner address of agent that will control the endpoint
    function createEndpointForOwner(uint256 nodeId_, address owner) external returns (address endpoint) {
        return IExecution(executionAddress).createEndpointForOwner(_msgSender(), nodeId_, owner);
    }

    /// @notice executes the signature queue identified by its hash if signing requirements
    function executeQueue(bytes32 SignatureQueueHash_) external returns (bool s) {
        return IExecution(executionAddress).executeQueue(SignatureQueueHash_);
    }

    /// @notice submits a list of signatures to a specific movement queue
    function submitSignatures(bytes32 sigHash, address[] memory signers, bytes[] memory signatures) external {
        return IExecution(executionAddress).submitSignatures(sigHash, signers, signatures);
    }

    function removeSignature(bytes32 sigHash_, uint256 index_) external {
        IExecution(executionAddress).removeSignature(sigHash_, index_, _msgSender());
    }

    /////////// View

    function _msgSender() internal view virtual override returns (address) {
        return msg.sender;
    }

    function getSigQueue(bytes32 hash_) public view returns (SignatureQueue memory) {
        return IExecution(executionAddress).getSigQueue(hash_);
    }

    function isQueueValid(bytes32 sigHash) public view returns (bool) {
        return IExecution(executionAddress).isQueueValid(sigHash);
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4) {
        return IExecution(executionAddress).isValidSignature(_hash, _signature);
    }
}
