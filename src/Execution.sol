// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SignatureChecker} from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SignatureQueue, SQState, MovementType, Movement, Call} from "./interfaces/IExecution.sol";
import {IFun} from "./interfaces/IFun.sol";
import {IPowerProxy} from "./interfaces/IPowerProxy.sol";
import {IERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import {EIP712} from "./info/EIP712.sol";
import {PowerProxy} from "./components/PowerProxy.sol";
import {Receiver} from "solady/accounts/Receiver.sol";

import "forge-std/console.sol";

/// @title Execution
/// @author parseb
contract Execution is EIP712, Receiver {
    using Address for address;
    using Strings for string;

    address public WillToken;
    IFun public WillWe;

    bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;
    bytes4 internal constant EIP1271_MAGIC_VALUE_LEGACY = 0x20c13b0b;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant MOVEMENT_TYPEHASH = keccak256(
        "Movement(uint8 category,address initiatior,address exeAccount,uint256 viaNode,uint256 expiresAt,bytes32 descriptionHash,bytes executedPayload)"
    );

    /// errors
    error UninitQueue();
    error ExpiredMovement();
    error InvalidQueue();
    error EmptyUnallowed();
    error NotNodeMember();
    error AlreadyInitialized();
    error UnavailableState();
    error ExpiredQueue();
    error NotExeAccOwner();
    error AlreadyHasEndpoint();
    error NoMembersForNode();
    error NoMovementType();
    error AlreadySigned();
    error LenErr();
    error AlreadyInit();
    error OnlyFun();
    error NoSignatures();
    error EXEC_SQInvalid();
    error EXEC_NoType();
    error EXEC_NoDescription();
    error EXEC_ZeroLen();
    error EXEC_A0sig();
    error EXEC_OnlyMore();
    error EXEC_OnlySigner();
    error EXEC_exeQFail();
    error EXEC_InProgress();
    error EXEC_ActionIndexMismatch();
    error EXEC_BadOwnerOrAuthType();

    /// events
    event NewMovementCreated(bytes32 indexed movementHash, uint256 indexed nodeId);
    event EndpointCreatedForAgent(uint256 indexed nodeId, address endpoint, address agent);
    event WillWeSet(address implementation);
    event NewSignaturesSubmitted(bytes32 indexed queueHash);
    event QueueExecuted(uint256 indexed nodeId, bytes32 indexed queueHash);
    event SignatureRemoved(uint256 indexed nodeId, bytes32 indexed queueHash, address signer);
    event LatentActionRemoved(uint256 indexed nodeId, bytes32 indexed actionHash, uint256 index);

    /// @notice signature by hash
    mapping(bytes32 hash => SignatureQueue SigQueue) getSigQueueByHash;

    /// @notice initialized actions from node [node -> latentActionsOfNode[] | [0] valid start index, prevs. 0]
    mapping(uint256 => bytes32[]) latentActions;

    /// @notice stores node that ownes a particular execution agent authorisation
    mapping(address exeAccount => uint256 endpointOwner) engineOwner;

    /// @notice any one agent is allowed to have only one endpoint
    /// @notice stores agent signatures to prevent double signing  | ( uint256(hash) - uint256(_msgSender()  ) - signer can be simple or composed agent
    mapping(uint256 agentPlusNode => bool) hasEndpointOrInteraction;

    constructor(address WillToken_) {
        WillToken = WillToken_;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH, keccak256(bytes("WillWe")), keccak256(bytes("1")), block.chainid, address(this)
            )
        );
    }

    function setWillWe(address implementation) external {
        if (address(WillWe) == address(0)) WillWe = IFun(implementation);
        if (msg.sender == WillToken) WillWe = IFun(implementation);
        emit WillWeSet(implementation);
    }

    function startMovement(
        address origin,
        uint8 typeOfMovement,
        uint256 nodeId,
        uint256 expiresInDays,
        address executingAccount,
        bytes32 descriptionHash,
        bytes memory data
    ) external virtual returns (bytes32 movementHash) {

        if (msg.sender != address(WillWe)) revert OnlyFun();
        if (typeOfMovement > 2 || typeOfMovement == 0) revert NoMovementType();
        if (!WillWe.isMember(origin, nodeId)) revert NotNodeMember();

        if (((typeOfMovement * nodeId * expiresInDays) == 0)) revert EmptyUnallowed();
        if (uint256(descriptionHash) == 0) revert EXEC_NoDescription();

        if (executingAccount == address(0)) {
            executingAccount = createNodeEndpoint(origin, nodeId, typeOfMovement);
            engineOwner[executingAccount] = nodeId;
        } else {
            if (!(engineOwner[executingAccount] == nodeId)) revert NotExeAccOwner();
            if (
                IPowerProxy(executingAccount).owner() != address(this)
                    || IPowerProxy(executingAccount).allowedAuthType() != typeOfMovement
            ) revert EXEC_BadOwnerOrAuthType();
        }

        Movement memory M;
        M.initiatior = msg.sender;
        M.viaNode = nodeId;
        M.descriptionHash = descriptionHash;
        M.executedPayload = data;
        M.exeAccount = executingAccount;
        M.expiresAt = (expiresInDays * 1 days) + block.timestamp;
        M.category = typeOfMovement == 1 ? MovementType.AgentMajority : MovementType.EnergeticMajority;

        movementHash = hashMessage(M);
        latentActions[nodeId].push(movementHash);

        SignatureQueue memory SQ;
        SQ.state = SQState.Initialized;
        SQ.Action = M;

        if (getSigQueueByHash[movementHash].state != SQState.None) revert AlreadyInitialized();
        getSigQueueByHash[movementHash] = SQ;

        emit NewMovementCreated(movementHash, nodeId);
    }

    function executeQueue(bytes32 queueHash) public virtual returns (bool success) {
        if (msg.sender != address(WillWe)) revert OnlyFun();

        SignatureQueue memory SQ = validateQueue(queueHash);

        if (SQ.state != SQState.Valid) revert InvalidQueue();
        if (SQ.Action.expiresAt <= block.timestamp) revert ExpiredMovement();

        Movement memory M = SQ.Action;

        SQ.state = SQState.Executed;
        getSigQueueByHash[queueHash] = SQ;

        (success,) = (SQ.Action.exeAccount).call(M.executedPayload);
        if (!success) revert EXEC_exeQFail();

        emit QueueExecuted(SQ.Action.viaNode, queueHash);
    }

    function submitSignatures(bytes32 queueHash, address[] memory signers, bytes[] memory signatures) external {
        if (msg.sender != address(WillWe)) revert OnlyFun();

        SignatureQueue memory SQ = getSigQueueByHash[queueHash];

        if (signatures.length < SQ.Sigs.length) revert EXEC_OnlyMore();
        if (signers.length * signatures.length == 0) revert EXEC_ZeroLen();
        if (signers.length != signatures.length) revert LenErr();

        bytes32 structHash = hashMessage(SQ.Action);
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        uint256 validCount;
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == address(0)) revert EXEC_A0sig();

            if (hasEndpointOrInteraction[uint256(queueHash) - uint160(signers[i])]) {
                continue;
            }

            if (!(WillWe.isMember(signers[i], SQ.Action.viaNode))) {
                continue;
            }

            (uint8 v, bytes32 r, bytes32 s) = splitSignature(signatures[i]);
            address recovered = ecrecover(digest, v, r, s);
            if (recovered != signers[i]) continue;

            hasEndpointOrInteraction[uint256(queueHash) - uint160(signers[i])] = true;
            validCount++;
        }

        if (validCount > 0) {
            uint256 newSize = SQ.Signers.length + validCount;
            address[] memory newSigners = new address[](newSize);
            bytes[] memory newSignatures = new bytes[](newSize);

            for (uint256 i = 0; i < SQ.Signers.length; i++) {
                newSigners[i] = SQ.Signers[i];
                newSignatures[i] = SQ.Sigs[i];
            }

            uint256 j = SQ.Signers.length;
            for (uint256 i = 0; i < signers.length; i++) {
                if (hasEndpointOrInteraction[uint256(queueHash) - uint160(signers[i])]) {
                    newSigners[j] = signers[i];
                    newSignatures[j] = signatures[i];
                    j++;
                }
            }

            getSigQueueByHash[queueHash].Signers = newSigners;
            getSigQueueByHash[queueHash].Sigs = newSignatures;
        }
        emit NewSignaturesSubmitted(queueHash);
    }

    function removeSignature(bytes32 queueHash, uint256 index, address signer) external {
        if (msg.sender != address(WillWe)) revert OnlyFun();
        SignatureQueue memory SQ = getSigQueueByHash[queueHash];

        if (SQ.Signers[index] != signer) revert EXEC_OnlySigner();
        delete SQ.Sigs[index];
        delete SQ.Signers[index];
        getSigQueueByHash[queueHash] = SQ;
        hasEndpointOrInteraction[uint256(queueHash) - uint160(signer)] = false;

        emit SignatureRemoved(SQ.Action.viaNode, queueHash, signer);
    }

    function removeLatentAction(bytes32 actionHash, uint256 index) external {
        SignatureQueue memory SQ = getSigQueueByHash[actionHash];
        if (SQ.Action.expiresAt > block.timestamp) SQ.state = SQState.Stale;
        if (SQ.state == SQState.Initialized || SQ.state == SQState.Valid) revert EXEC_InProgress();
        if (latentActions[SQ.Action.viaNode][index] != actionHash) revert EXEC_ActionIndexMismatch();
        delete latentActions[SQ.Action.viaNode][index];
        if (uint256(latentActions[SQ.Action.viaNode][0]) > index) latentActions[SQ.Action.viaNode][0] = bytes32(index);
        getSigQueueByHash[actionHash] = SQ;

        emit LatentActionRemoved(SQ.Action.viaNode, actionHash, index);
    }

    function createEndpointForOwner(address origin, uint256 nodeId, address owner)
        external
        returns (address endpoint)
    {
        if ((msg.sender != address(WillWe) && owner != address(this))) revert OnlyFun();
        if (!WillWe.isMember(origin, nodeId) && owner != address(this)) revert NotNodeMember();
        if (hasEndpointOrInteraction[nodeId + uint160(bytes20(owner))]) revert AlreadyHasEndpoint();
        hasEndpointOrInteraction[nodeId + uint160(bytes20(owner))] = true;

        endpoint = createNodeEndpoint(origin, nodeId, 3);

        emit EndpointCreatedForAgent(nodeId, endpoint, owner);
    }

    function createNodeEndpoint(address originOrNode, uint256 endpointOwner_, uint8 consensusType)
        internal
        returns (address endpoint)
    {
        if (msg.sig == this.createEndpointForOwner.selector) {
            endpoint = spawnNodeEndpoint(originOrNode, 3);
            engineOwner[endpoint] = originOrNode == address(this) ? endpointOwner_ : uint160(originOrNode);
        } else {
            endpoint = spawnNodeEndpoint(address(this), consensusType);
            engineOwner[endpoint] = endpointOwner_;
        }
        WillWe.localizeEndpoint(endpoint, endpointOwner_, originOrNode);
    }

    function spawnNodeEndpoint(address proxyOwner_, uint8 authType) private returns (address) {
        return address(new PowerProxy(proxyOwner_, authType));
    }

    function validateQueue(bytes32 sigHash) internal returns (SignatureQueue memory SQM) {
        SQM = getSigQueueByHash[sigHash];
        if (SQM.Action.expiresAt <= block.timestamp) {
            SQM.state = SQState.Stale;
            getSigQueueByHash[sigHash] = SQM;
        }
        bytes32 hashedOne = hashMovement(SQM.Action);
        if (!isQueueValid(hashedOne)) revert EXEC_SQInvalid();

        SQM.state = SQState.Valid;
        getSigQueueByHash[sigHash] = SQM;
    }

    function isQueueValid(bytes32 sigHash) public view returns (bool) {
        SignatureQueue memory SQM = getSigQueueByHash[sigHash];

        if (SQM.Action.category == MovementType.Revert) return false;
        if (SQM.state == SQState.Valid) return true;
        if (SQM.state == SQState.Stale) return false;
        if (SQM.state != SQState.Initialized) return false;
        if (SQM.Signers.length == 0) return false;
        if (SQM.Signers.length != SQM.Sigs.length) return false;

        uint256 i;
        uint256 power;
        address[] memory signers = SQM.Signers;
        bytes[] memory signatures = SQM.Sigs;

        bytes32 signedHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, sigHash));

        for (i; i < signatures.length; ++i) {
            if (signers[i] == address(0)) continue;

            if (!SignatureChecker.isValidSignatureNow(signers[i], signedHash, signatures[i])) return false;

            power = (SQM.Action.category == MovementType.EnergeticMajority)
                ? power + WillWe.balanceOf(signers[i], SQM.Action.viaNode)
                : power + 1;
        }

        if (power > 0) {
            if (SQM.Action.category == MovementType.EnergeticMajority) {
                return (power > ((WillWe.totalSupply(SQM.Action.viaNode) / 2)));
            }
            if (SQM.Action.category == MovementType.AgentMajority) {
                return (power > ((WillWe.allMembersOf(SQM.Action.viaNode).length / 2)));
            }
        }
        return false;
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4) {
        if (getSigQueueByHash[_hash].state == SQState.Valid) return EIP1271_MAGICVALUE;
    }

    /// @notice retrieves the node or agent that owns the execution account
    /// @param endpointAddress execution account for which to retrieve owner
    /// @dev in case of user-driven endpoints the returned value is uint160(address of endpoint creator)
    function endpointOwner(address endpointAddress) public view returns (uint256) {
        return engineOwner[endpointAddress];
    }

    function getSigQueue(bytes32 hash_) public view returns (SignatureQueue memory) {
        return getSigQueueByHash[hash_];
    }

    function hashMovement(Movement memory movement) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                MOVEMENT_TYPEHASH,
                movement.category,
                movement.initiatior,
                movement.exeAccount,
                movement.viaNode,
                movement.expiresAt,
                movement.descriptionHash,
                keccak256(movement.executedPayload)
            )
        );
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");
    }
}
