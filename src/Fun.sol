// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {Fungido} from "./Fungido.sol";
import {IExecution, SignatureQueue} from "./interfaces/IExecution.sol";

import {Call} from "./interfaces/IFun.sol";

/////////////////////////////////////////
/// @title Fun
/// @author parseb
///////////////////////////////////////////////

contract Fun is Fungido {
    constructor(address ExeAddr, address Membranes_) Fungido(ExeAddr, Membranes_) {
        executionAddress = ExeAddr;
        IExecution(ExeAddr).setBagBook(address(this));
    }

    error BadLen();
    error Noise();
    error NoSoup();
    error MembraneNotFound();
    error RootNodeOrNone();

    event Signal(uint256 indexed nodeID, address origin, uint256 value);
    event NewMovement(uint256 indexed nodeID, bytes32 movementID, bytes32 descriptionHash);

    /// @notice processes and stores user signal
    /// @notice in case threashold is reached, the change is applied.
    /// @notice formatted as follows: membrane, inflation, [recognition]
    /// @param targetNode_ node for which to signal
    /// @param signals array of signaling values constructed starting with membrane, inflation, and [redistributive preferences for sub-entities]
    /// @dev skips values over 100_00
    function sendSignal(uint256 targetNode_, uint256[] memory signals) external {
        if (parentOf[targetNode_] == targetNode_) revert RootNodeOrNone();
        if (!(isMember(msg.sender, targetNode_))) revert NotMember();

        mintInflation(targetNode_);

        uint256 user = toID(_msgSender());
        uint256 balanceOfSender = balanceOf(_msgSender(), targetNode_);
        uint256 targetTotalS = totalSupplyOf[targetNode_];
        if (balanceOfSender < targetTotalS / 100_00) revert Noise();

        uint256 i;
        uint256 sigSum;

        for (i; i < signals.length; ++i) {
            emit Signal(targetNode_, _msgSender(), signals[i]);

            if (i <= 1) {
                if (signals[i] == 0) continue;

                bytes32 userKey = keccak256((abi.encodePacked(targetNode_, user, signals[i])));
                bytes32 nodeKey = keccak256((abi.encodePacked(targetNode_, signals[i])));

                childrenOf[targetNode_ + user - 1].push(signals[0]);
                childrenOf[targetNode_ + user - 2].push(signals[1]);

                if (i == 0) {
                    i = signals[i];
                    if (i < type(uint160).max) revert BadLen();
                    if (!(M.getMembraneById(i).tokens.length > 0)) revert MembraneNotFound();

                    if (options[userKey][1] > 0 && (inUseMembraneId[targetNode_][1] < options[userKey][1])) {
                        options[nodeKey][0] -= options[userKey][0];
                    }

                    options[userKey] = [i, block.timestamp];
                    options[nodeKey][0] += balanceOfSender;

                    if (options[nodeKey][0] * 2 > totalSupplyOf[targetNode_]) {
                        delete  options[nodeKey][0];
                        options[nodeKey][1] = block.timestamp;

                        inUseMembraneId[targetNode_][0] = i;
                        inUseMembraneId[targetNode_][1] = block.timestamp;
                    }

                    delete i;
                } else {
                    i = signals[i];
                    if (options[userKey][1] > 0 && (inflSec[targetNode_][1] < options[userKey][1])) {
                        options[nodeKey][0] -= options[userKey][0];
                    }

                    options[userKey] = [i, block.timestamp];
                    options[nodeKey][0] += balanceOfSender;

                    if (options[nodeKey][0] * 2 > totalSupplyOf[targetNode_]) {
                        delete  options[nodeKey][0];
                        options[nodeKey][1] = block.timestamp;

                        inflSec[targetNode_][0] = i * 1 gwei;
                        inflSec[targetNode_][1] = block.timestamp;
                    }

                    i = 1;
                }

                continue;
            }
            if (signals[i] > 100_00) continue;
            sigSum += signals[i];
            if (sigSum > 100_00) revert SignalOverflow();

            uint256[] memory children = childrenOf[targetNode_];
            if (children.length != (signals.length - 2)) revert BadLen();
            bytes32 userTargetedPreference = keccak256((abi.encodePacked(user, targetNode_, children[i - 2])));

            if (!(options[userTargetedPreference][0] == signals[i])) {
                options[userTargetedPreference][0] = signals[i];
                options[userTargetedPreference][1] = block.timestamp;

                redistribute(children[i - 2]);

                bytes32 childParentEligibilityPerSec = keccak256((abi.encodePacked(children[i - 2], targetNode_)));

                options[childParentEligibilityPerSec][0] = options[childParentEligibilityPerSec][0]
                    > options[userTargetedPreference][1]
                    ? options[childParentEligibilityPerSec][0] - options[userTargetedPreference][1]
                    : 0;

                options[userTargetedPreference][1] = (balanceOfSender * 1 ether / targetTotalS)
                    * (signals[i] * inflSec[targetNode_][0] / 100_00) / 1 ether;
                options[childParentEligibilityPerSec][0] += options[userTargetedPreference][1];

                options[childParentEligibilityPerSec][1] = block.timestamp;
            }
        }
        if (sigSum != 0 && sigSum != 100_00) revert IncompleteSign();
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

    function proposeMovement(
        uint256 typeOfMovement,
        uint256 node_,
        uint256 expiresInDays,
        address executingAccount,
        bytes32 descriptionHash,
        bytes memory data
    ) external returns (bytes32 movementHash) {
        movementHash = IExecution(executionAddress).proposeMovement(
            _msgSender(), typeOfMovement, node_, expiresInDays, executingAccount, descriptionHash, data
        );
        emit NewMovement(node_, movementHash, descriptionHash);
    }

    function createEndpointForOwner(uint256 nodeId_, address owner) external returns (address endpoint) {
        return IExecution(executionAddress).createEndpointForOwner(_msgSender(), nodeId_, owner);
    }

    function executeQueue(bytes32 SignatureQueueHash_) external returns (bool s) {
        return IExecution(executionAddress).executeQueue(SignatureQueueHash_);
    }

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
