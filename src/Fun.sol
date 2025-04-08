// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {Fungido} from "./Fungido.sol";
import {IExecution} from "./interfaces/IExecution.sol";

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
    error NotNodeMember();
    error UnsoundMembership();

    event ConfigSignal(uint256 indexed nodeId, bytes32 expressedOption);
    event CreatedEndpoint(address indexed endpoint, address indexed owner, uint256 indexed nodeId);
    event Resignaled(address indexed sender, uint256 indexed nodeId, address origin);
    event MembraneSignal(uint256 indexed nodeId, address indexed origin, uint256 membraneId);
    event InflationSignal(uint256 indexed nodeId, address indexed origin, uint256 inflationRate);
    event UserNodeSignal(uint256 indexed nodeId, address indexed user, uint256[] signals);

    function resignal(uint256 targetNode_, address originator) public virtual {
        uint256[] memory signals = getUserNodeSignals(originator, targetNode_);

        if (signals.length <= 2) return;
        if (msg.sig == this.burn.selector || this.burnPath.selector == msg.sig) {
            uint256[] memory children = childrenOf[targetNode_];
            for (uint256 i = 2; i < signals.length && i - 2 < children.length; i++) {
                bytes32 userTargetedPreference = keccak256(abi.encodePacked(originator, targetNode_, children[i - 2]));
                bytes32 childParentEligibility = keccak256(abi.encodePacked(children[i - 2], targetNode_));

                if (options[userTargetedPreference][2] > 0) {
                    if (options[userTargetedPreference][2] >= options[childParentEligibility][0]) {
                        options[childParentEligibility][0] = 0;
                    } else {
                        options[childParentEligibility][0] -= options[userTargetedPreference][2];
                    }
                    options[userTargetedPreference][2] = 0;
                }
            }
        }

        impersonatingAddress = originator;
        sendSignal(targetNode_, signals);
        delete impersonatingAddress;
        emit Resignaled(msg.sender, targetNode_, originator);
    }

    function sendSignal(uint256 targetNode_, uint256[] memory signals) public virtual {
        bool isMember = isMember(_msgSender(), targetNode_);
        uint256 user = toID(_msgSender());
        if (parentOf[targetNode_] == targetNode_) revert TargetIsRoot();
        if (!isMember) revert Noise();

        uint256 balanceOfSender = balanceOf(_msgSender(), targetNode_);
        if (balanceOfSender < totalSupplyOf[targetNode_] / 100_00) revert NoiseNotVoice();

        mintInflation(targetNode_);

        uint256[] memory children = childrenOf[targetNode_];
        bytes32 signalsKey = keccak256(abi.encodePacked(_msgSender(), targetNode_));

        uint256 sigSum;
        uint256 i;
        for (i; i < signals.length; ++i) {
            uint256 signalValue = signals[i];
            bytes32 userKey = keccak256(abi.encodePacked(targetNode_, user, signalValue));

            if (i <= 1) {
                if (signalValue == 0) continue;
                if (i == 0) {
                    emit InflationSignal(targetNode_, _msgSender(), signalValue);
                } else {
                    emit MembraneSignal(targetNode_, _msgSender(), signalValue);
                }
                _handleSpecialSignals(targetNode_, signalValue, i, balanceOfSender, userKey, signalsKey);
            } else {
                _handleRegularSignals(targetNode_, user, signalValue, i, signals.length, children);
                sigSum += signalValue;
            }
        }
        if (signals.length >= 3 && sigSum != 0 && sigSum != 100_00) revert IncompleteSign();
        emit UserNodeSignal(targetNode_, toAddress(user), signals);

        if (impersonatingAddress == address(0)) {
            userNodeSignals[keccak256(abi.encodePacked(_msgSender(), targetNode_))] = signals;
        }
    }

    function _handleSpecialSignals(
        uint256 targetNode_,
        uint256 signal,
        uint256 index,
        uint256 balanceOfSender,
        bytes32 userKey,
        bytes32 signalsKey
    ) private {
        if (signal == 0) return;
        bytes32 nodeKey = keccak256(abi.encodePacked(targetNode_, signal));

        if (block.timestamp == options[userKey][1]) revert NoTimeDelta();
        if (index == 0) {
            _handleMembraneSignal(targetNode_, userKey, nodeKey, signal, balanceOfSender, signalsKey, index);
        } else {
            _handleInflationSignal(targetNode_, userKey, nodeKey, signal, balanceOfSender, signalsKey, index);
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
        uint256 balanceOfSender,
        bytes32 signalsKey,
        uint256 index
    ) private {
        if (signal < type(uint160).max || bytes(M.getMembraneById(signal).meta).length == 0) revert MembraneNotFound();
        _updateSignalOption(userKey, nodeKey, signal, balanceOfSender, signalsKey, index, targetNode_);
        if (options[nodeKey][0] * 2 > totalSupplyOf[targetNode_]) {
            (bool s,) = M.integrityCheck(targetNode_);
            if (!s) revert UnsoundMembership();
            emit MembraneChanged(targetNode_, inUseMembraneId[targetNode_][0], signal);
            inUseMembraneId[targetNode_] = [signal, block.timestamp];
        }
    }

    function _handleInflationSignal(
        uint256 targetNode_,
        bytes32 userKey,
        bytes32 nodeKey,
        uint256 signal,
        uint256 balanceOfSender,
        bytes32 signalsKey,
        uint256 index
    ) private {
        _updateSignalOption(userKey, nodeKey, signal, balanceOfSender, signalsKey, index, targetNode_);
        if (options[nodeKey][0] * 2 > totalSupplyOf[targetNode_]) {
            (bool s,) = M.integrityCheck(targetNode_);
            if (!s) revert UnsoundMembership();
            mintInflation(targetNode_);
            emit InflationRateChanged(targetNode_, inflSec[targetNode_][0], signal * 1 gwei);
            _handleInflationUpdate(targetNode_, inflSec[targetNode_][0], signal * 1 gwei);
            inflSec[targetNode_] = [signal * 1 gwei, block.timestamp, block.timestamp];
        }
    }

    function _handleInflationUpdate(uint256 nodeId, uint256 oldRate, uint256 newRate) private {
        uint256[] memory children = childrenOf[nodeId];
        if (children.length == 0) return;
        uint256 oldTotalEligibilitySum;
        for (uint256 i = 0; i < children.length; i++) {
            bytes32 childParentEligibility = keccak256(abi.encodePacked(children[i], nodeId));
            uint256 currentEligibility = options[childParentEligibility][0];
            oldTotalEligibilitySum += currentEligibility;

            if (currentEligibility > 1 gwei) {
                redistribute(children[i]);
                uint256 newEligibility = (currentEligibility * newRate) / oldRate;
                options[childParentEligibility][0] = newEligibility;
            }
        }

        if ((oldTotalEligibilitySum > 1) && (oldTotalEligibilitySum / 100000) < (inflSec[nodeId][0] / 100000)) {
            uint256 surplusAmount =
                balanceOf(toAddress(nodeId), nodeId) - balanceOf(toAddress(nodeId), parentOf[nodeId]);
            _burn(toAddress(nodeId), nodeId, surplusAmount);
        }

        inflSec[nodeId] = [newRate, block.timestamp, block.timestamp];

        emit InflationRateChanged(nodeId, oldRate, newRate);
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

        if (prevSignal != signal || impersonatingAddress != address(0)) {
            if (prevSignal != signal) {
                options[userTargetedPreference][0] = signal;
                options[userTargetedPreference][1] = block.timestamp;
            }

            redistribute(children[index - 2]);
            _updateChildParentEligibility(children[index - 2], targetNode_, userTargetedPreference);
        }
    }

    function _updateSignalOption(
        bytes32 userKey,
        bytes32 nodeKey,
        uint256 signal,
        uint256 balanceOfSender,
        bytes32 signalsKey,
        uint256 sIndex,
        uint256 targetNode
    ) private {
        if (options[userKey][1] > 0) {
            if (options[userKey][2] > 0 && (options[userKey][1] > 0)) {
                options[nodeKey][0] -= options[userKey][2];
            }
        }
        if (userNodeSignals[signalsKey].length > sIndex) {
            uint256 pastSignal = userNodeSignals[signalsKey][sIndex];
            if (pastSignal != signal) {
                options[keccak256(abi.encodePacked(targetNode, pastSignal))][0] -=
                    options[keccak256(abi.encodePacked(targetNode, _msgSender(), pastSignal))][2];
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

        if (options[userTargetedPreference][2] >= options[childParentEligibilityPerSec][0]) {
            options[childParentEligibilityPerSec][0] = 0;
        } else {
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

    function _burn(address who_, uint256 fid_, uint256 amount_) internal override {
        super._burn(who_, fid_, amount_);
        if (totalSupplyOf[toID(who_)] >= 1) return;
        resignal(fid_, who_);
    }

    /////////// External

    /// @notice creates an external endpoint for an agent in node context
    /// @notice node owner can be external
    /// @param nodeId_ id of context node
    /// @param owner address of agent that will control the endpoint
    /// @return endpointAddress address of created endpoint
    function createEndpointForOwner(uint256 nodeId_, address owner) external returns (address endpointAddress) {
        if (!isMember(owner, nodeId_)) revert NotNodeMember();
        endpointAddress = IExecution(executionAddress).createEndpointForOwner(msg.sender, nodeId_, owner);
        emit CreatedEndpoint(endpointAddress, owner, nodeId_);
    }

    /////////// View

    function calculateUserTargetedPreferenceAmount(uint256 childId, uint256 parentId, uint256 signal, address user)
        public
        view
        returns (uint256)
    {
        if (parentOf[childId] != parentId) revert UnregisteredFungible();

        uint256 totalSupplyParent = balanceOf(toAddress(parentId), parentOf[parentId]);
        uint256 balanceOfSenderParent = balanceOf(user, parentId);
        uint256 parentInflationRate = inflSec[parentId][0];
        if (balanceOfSenderParent <= 1 gwei) return 0;
        uint256 newContribution = (balanceOfSenderParent * signal * parentInflationRate) / (totalSupplyParent * 100_00);

        return newContribution;
    }

    function getChangePrevalence(uint256 nodeId_, uint256 signal_) public view returns (uint256) {
        return options[keccak256(abi.encodePacked(nodeId_, signal_))][0];
    }
}
