// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Fungido} from "./Fungido.sol";
import {IExecution, SignatureQueue} from "./interfaces/IExecution.sol";
import {SafeTx} from "./interfaces/IFun.sol";
/// @title Fungido
/// @author   parseb

///////////////////////////////////////////////
////////////////////////////////////
import {console} from "forge-std/console.sol";

contract Fun is Fungido {
    /// @notice stores an users option for change: node + user * value -> [ wanted value, lastExpressedAt ]
    mapping(bytes32 NodeXUserXValue => uint256[2] valueAtTime) options;

    bytes constant REDIST = abi.encodePacked("redistribution");

    constructor(address ExeAddr) Fungido(ExeAddr) {
        executionAddress = ExeAddr;

        IExecution(ExeAddr).setSelfFungi();
    }

    event MembraneChanged(uint256 indexed targetNode, uint256 membraneID);
    event InflationChanged(uint256 indexed targetNode, uint256 newInflation);

    error BadLen();
    error Noise();
    error NoSoup();

    /// @notice processes and stores user signal
    /// @notice in case threashold is reached, the change is applied.
    /// @notice formatted as follows: membrane, inflation, [recognition]
    /// @param targetNode_ node for which to signal
    /// @param signals array of signaling values constructed starting with membrane, inflation, and [redistributive preferences for sub-entities]

    function sendSignal(uint256 targetNode_, uint256[] memory signals) external returns (bool s) {
        //// @dev could use one hash and substract to same effect for gas efficiency or precreate... naah.
        if (!isMember(_msgSender(), targetNode_)) revert NotMember();

        s = isMember(_msgSender(), targetNode_);

        mintInflation(targetNode_);

        uint256 user = toID(_msgSender());
        uint256 balanceOfSender = balanceOf(_msgSender(), targetNode_);
        uint256 targetTotalS = totalSupplyOf[targetNode_];
        if (balanceOfSender < targetTotalS / 100_00) revert Noise();

        uint256 i;

        for (i; i < signals.length;) {
            if (i <= 1) {
                if (signals[i] == 0) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }

                bytes32 userKey = keccak256((abi.encodePacked(targetNode_, user, signals[i])));
                bytes32 nodeKey = keccak256((abi.encodePacked(targetNode_, signals[i])));

                if (i == 0) {
                    i = signals[i];
                    if (i < type(uint160).max) revert BadLen();
                    if (!(getMembraneById[i].tokens.length > 0)) revert membraneNotFound();
                    /// membrane

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
                        emit MembraneChanged(targetNode_, i);
                    }

                    delete i;
                } else {
                    mintInflation(targetNode_);
                    /// inflation | i == 1
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

                        emit InflationChanged(targetNode_, i);
                    }

                    i = 1;
                }
                unchecked {
                    ++i;
                }
                continue;
            }
            /// redistribution zone
            uint256[] memory children = childrenOf[targetNode_];
            if (children.length != (signals.length - 2)) revert BadLen();

            uint256 totalInflPerSec = inflSec[targetNode_][0];

            bytes32 userTargetedPreference = keccak256((abi.encodePacked(user, targetNode_, children[i - 2])));

            //// 0 percentagee - 1 in units per sec
            if (!(options[userTargetedPreference][0] == signals[i])) {
                //// expressed option differes from existing one
                options[userTargetedPreference][0] = signals[i];
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

            unchecked {
                ++i;
            }
        }
    }

    function redistribute(uint256 nodeId_) public returns (uint256 distributedAmt) {
        uint256 parent = parentOf[nodeId_];
        if (parent == 0) revert NoSoup();
        mintInflation(nodeId_);

        bytes32 childParentEligibility = keccak256((abi.encodePacked(nodeId_, parent)));
        distributedAmt = options[childParentEligibility][0] * (block.timestamp - options[childParentEligibility][1]);

        _mint(address(uint160(nodeId_)), parent, distributedAmt, REDIST);
    }

    function taxPolicyPreference(address rootToken_, uint256 taxDivBy_) external returns (uint256 inForceTaxRate) {
        return 1;
    }

    function proposeMovement(
        uint256 typeOfMovement,
        uint256 node_,
        uint256 expiresInDays,
        address executingAccount,
        bytes32 descriptionHash,
        SafeTx memory data
    ) external returns (bytes32 movementHash) {
        console.log("calling execution..propose..");
        return IExecution(executionAddress).proposeMovement(
            _msgSender(), typeOfMovement, node_, expiresInDays, executingAccount, descriptionHash, data
        );
    }

    function _msgSender() internal view virtual override returns (address) {
        return msg.sender;
    }

    function getSigQueue(bytes32 hash_) public view returns (SignatureQueue memory) {
        return IExecution(executionAddress).getSigQueue(hash_);
    }

    function createEndpointForOwner(uint256 nodeId_, address owner) external returns (address endpoint) {
        return IExecution(executionAddress).createEndpointForOwner(_msgSender(), nodeId_, owner);
    }

    function executeQueue(bytes32 SignatureQueueHash_) external returns (bool s) {
        return IExecution(executionAddress).executeQueue(_msgSender(), SignatureQueueHash_);
    }

    function submitSignatures(bytes32 sigHash, address[] memory signers, bytes[] memory signatures) external {
        return IExecution(executionAddress).submitSignatures(_msgSender(), sigHash, signers, signatures);
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4) {
        return IExecution(executionAddress).isValidSignature(_hash, _signature);
    }

    function endpointOwner(address endpointAddress) external view returns (uint256) {
        return IExecution(executionAddress).endpointOwner(endpointAddress);
    }

    function membershipEnforce(address target, uint256 fid_) public override returns (bool s) {
        return super.membershipEnforce(target, fid_);
    }

    function mintInflation(uint256 node) public override returns (uint256 amount) {
        return super.mintInflation(node);
    }

    function burn(uint256 fid_, uint256 amount_) public override returns (bool) {
        return super.burn(fid_, amount_);
    }

    function mint(uint256 fid_, uint256 amount_) public override {
        super.mint(fid_, amount_);
    }

    function mintMembership(uint256 fid_, address to_) public override returns (uint256 mID) {
        return super.mintMembership(fid_, to_);
    }

    function spawnBranchWithMembrane(uint256 fid_, uint256 membraneID_) public override returns (uint256 newID) {
        return super.spawnBranchWithMembrane(fid_, membraneID_);
    }

    function spawnBranch(uint256 fid_) public override returns (uint256 newID) {
        return super.spawnBranch(fid_);
    }

    function spawnRootBranch(address fungible20_) public override returns (uint256 fID) {
        return super.spawnRootBranch(fungible20_);
    }
}
