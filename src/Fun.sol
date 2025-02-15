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

    error BadLen();
    error Noise();
    error NoSoup();
    error MembraneNotFound();
    error NoiseNotVoice();
    error TargetIsRoot();
    error ResignalMismatch();
    error NoTimeDelta();
    error CannotSkip();

    event NewMovement(uint256 indexed nodeId, bytes32 movementHash, string description);
    event InflationRateChanged(uint256 indexed nodeId, uint256 oldInflationRate, uint256 newInflationRate);
    event MembraneChanged(uint256 indexed nodeId, uint256 previousMembrane, uint256 newMembrane);
    event Signaled(uint256 indexed nodeId, address sender, address origin);
    event ConfigSignal(uint256 indexed nodeId, bytes32 expressedOption);

    function resignal(uint256 targetNode_, uint256[] memory signals, address originator) public virtual {
        impersonatingAddress = originator;
        sendSignal(targetNode_, signals);
        delete impersonatingAddress;
    }

    function _msgSender() internal view override returns (address) {
        if (msg.sig == this.resignal.selector && impersonatingAddress != address(0)) {
            return impersonatingAddress;
        }
        return msg.sender;
    }

    function sendSignal(uint256 targetNode_, uint256[] memory signals) public virtual {
        if (parentOf[targetNode_] == targetNode_) revert TargetIsRoot();
        bool isMember = isMember(_msgSender(), targetNode_);
        if (impersonatingAddress == address(0) && (!isMember)) revert Noise();

        uint256 balanceOfSender = balanceOf(_msgSender(), targetNode_);
        if (balanceOf(_msgSender(), targetNode_) < totalSupplyOf[targetNode_] / 100_00) revert NoiseNotVoice();
        mintInflation(targetNode_);

        uint256 user = toID(_msgSender());
        uint256[] memory children = childrenOf[targetNode_];

        uint256 sigSum;

        for (uint256 i; i < signals.length; ++i) {
            bytes32 userKey = keccak256(abi.encodePacked(targetNode_, user, signals[i]));

            if (impersonatingAddress != address(0) && isMember && options[userKey][0] != signals[i]) {
                revert ResignalMismatch();
            }
            if ((!isMember) && signals[i] > 0) revert ResignalMismatch();
            if (i <= 1) {
                if (signals[i] == 0) continue;
                _handleSpecialSignals(targetNode_, signals[i], i, balanceOfSender, userKey);
            } else {
                _handleRegularSignals(targetNode_, user, signals[i], i, signals.length, children);
                sigSum += signals[i];
            }
        }
        if (sigSum != 0 && sigSum != 100_00) revert IncompleteSign();
        emit Signaled(targetNode_, address(uint160(user)), msg.sender);
    }

    function _handleSpecialSignals(
        uint256 targetNode_,
        uint256 signal,
        uint256 index,
        uint256 balanceOfSender,
        bytes32 userKey
    ) private {
        if (signal == 0) return;
        // bytes32 userKey = keccak256(abi.encodePacked(targetNode_, user, signal));
        bytes32 nodeKey = keccak256(abi.encodePacked(targetNode_, signal));

        if (block.timestamp == options[userKey][1]) revert NoTimeDelta();
        if (index == 0) {
            _handleMembraneSignal(targetNode_, userKey, nodeKey, signal, balanceOfSender);
        } else {
            _handleInflationSignal(targetNode_, userKey, nodeKey, signal, balanceOfSender);
        }

        options[userKey][1] = block.timestamp;
        childrenOf[uint256(userKey)].push(signal);

        emit ConfigSignal(targetNode_, nodeKey);
    }

    function _handleMembraneSignal(
        uint256 targetNode_,
        bytes32 userKey,
        bytes32 nodeKey,
        uint256 signal,
        uint256 balanceOfSender
    ) private {
        if (signal < type(uint160).max || bytes(M.getMembraneById(signal).meta).length == 0) revert MembraneNotFound();
        _updateSignalOption(targetNode_, userKey, nodeKey, signal, balanceOfSender);
        if (options[nodeKey][0] * 2 > totalSupplyOf[targetNode_]) {
            mintInflation(targetNode_);
            emit MembraneChanged(targetNode_, inUseMembraneId[targetNode_][0], signal);
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
            mintInflation(targetNode_);
            emit InflationRateChanged(targetNode_, inflSec[targetNode_][0], signal * 1 gwei);
            inflSec[targetNode_] = [signal * 1 gwei, block.timestamp, block.timestamp];
        }
    }

    function _handleRegularSignals(
        uint256 targetNode_,
        uint256 user,
        uint256 signal,
        uint256 index,
        uint256 signalsLength,
        uint256[] memory children
    ) private {
        if (children.length != (signalsLength - 2)) revert BadLen();
        bytes32 userTargetedPreference =
            keccak256(abi.encodePacked(address(uint160(user)), targetNode_, children[index - 2]));
        uint256 prevSignal = options[userTargetedPreference][0];
        if (signal > 100_00 && prevSignal == 0) return;
        if (signal > 100_00) revert CannotSkip();

        if (prevSignal != signal) {
            options[userTargetedPreference] = [signal, block.timestamp, 0];
            redistribute(children[index - 2]);
            _updateChildParentEligibility(children[index - 2], targetNode_, userTargetedPreference);
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
            if (options[userKey][2] > 0) {
                options[nodeKey][0] -= options[userKey][2];
            }
        }
        options[userKey] = [signal, block.timestamp, balanceOfSender];
        options[nodeKey][0] += balanceOfSender;
    }

    function _updateChildParentEligibility(uint256 childId, uint256 parentId, bytes32 userTargetedPreference) private {
        bytes32 childParentEligibilityPerSec = keccak256(abi.encodePacked(childId, parentId));
        uint256 newContribution =
            calculateUserTargetedPreferenceAmount(childId, parentId, options[userTargetedPreference][0], _msgSender());

        if (!(block.timestamp >= options[userTargetedPreference][1])) revert NoTimeDelta();
        if (options[userTargetedPreference][2] > 0) {
            options[childParentEligibilityPerSec][0] -= options[userTargetedPreference][2];
        }

        options[childParentEligibilityPerSec][0] += newContribution;
        if (options[childParentEligibilityPerSec][0] > inflSec[parentId][0]) {
            options[childParentEligibilityPerSec][0] = inflSec[parentId][0];
        }

        options[childParentEligibilityPerSec][1] = block.timestamp;
        options[userTargetedPreference][1] = block.timestamp;
        options[userTargetedPreference][2] = newContribution;
    }

    /// @notice redistributes eligible acummulated inflationary flows
    /// @param nodeId_ redistribution target group
    function redistribute(uint256 nodeId_) public returns (uint256 distributedAmt) {
        uint256 parent = parentOf[nodeId_];
        if (parent == 0) revert NoSoup();
        if (parentOf[parent] == parent) return 0;

        mintInflation(parent);

        bytes32 childParentEligibility = keccak256((abi.encodePacked(nodeId_, parent)));

        uint256 availableBalance = balanceOf(toAddress(parent), parent);
        distributedAmt = options[childParentEligibility][0] * (block.timestamp - options[childParentEligibility][1]);

        if (distributedAmt > availableBalance) {
            distributedAmt = availableBalance;
        }

        options[childParentEligibility][1] = block.timestamp;

        if (distributedAmt > 0) {
            _safeTransfer(
                toAddress(parent), toAddress(nodeId_), parent, distributedAmt, abi.encodePacked("redistribution")
            );
        }
    }

    /// @notice redistributes eligible amounts to all nodes on target path and mints inflation for target
    /// @param nodeId_ target node to actualize path to and mint inflation for
    function redistributePath(uint256 nodeId_) external returns (uint256 distributedAmt) {
        uint256[] memory path = getFidPath(nodeId_);
        distributedAmt = 1;
        for (distributedAmt; distributedAmt < path.length; ++distributedAmt) {
            redistribute(path[distributedAmt]);
        }
        mintInflation(nodeId_);
        distributedAmt = redistribute(nodeId_);
    }

    /////////// External

    //// @notice instantiates a new movement
    //// @param typeOfMovement 1 agent majority 2 value majority
    //// @param node identifiable atomic entity doing the moving, must be owner of the executing account
    /// @param expiresInDays deadline for expiry now plus days
    /// @param executingAccount external address acting as execution environment for movement
    /// @param description description of movement or description CID
    /// @param data calldata for execution call or executive payload
    function startMovement(
        uint8 typeOfMovement,
        uint256 node,
        uint256 expiresInDays,
        address executingAccount,
        string memory description,
        bytes memory data
    ) external returns (bytes32 movementHash) {
        movementHash = IExecution(executionAddress).startMovement(
            _msgSender(), typeOfMovement, node, expiresInDays, executingAccount, description, data
        );
        emit NewMovement(node, movementHash, description);
    }

    /// @notice creates an external endpoint for an agent in node context
    /// @notice node owner can be external
    /// @param nodeId_ id of context node
    /// @param owner address of agent that will control the endpoint
    function createEndpointForOwner(uint256 nodeId_, address owner) external returns (address) {
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

    function getSigQueue(bytes32 hash_) public view returns (SignatureQueue memory) {
        return IExecution(executionAddress).getSigQueue(hash_);
    }

    function isQueueValid(bytes32 sigHash) public view returns (bool) {
        return IExecution(executionAddress).isQueueValid(sigHash);
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4) {
        return IExecution(executionAddress).isValidSignature(_hash, _signature);
    }

    function calculateUserTargetedPreferenceAmount(uint256 childId, uint256 parentId, uint256 signal, address user)
        public
        view
        returns (uint256)
    {
        if (parentOf[childId] != parentId) revert UnregisteredFungible();

        uint256 totalSupplyParent = totalSupplyOf[parentId];
        uint256 balanceOfSenderParent = balanceOf(user, parentId);
        uint256 parentInflationRate = inflSec[parentId][0];
        if (balanceOfSenderParent <= 1 gwei) return 0;

        uint256 newContribution = (balanceOfSenderParent * signal * parentInflationRate) / (totalSupplyParent * 100_00);

        return newContribution;
    }
}
