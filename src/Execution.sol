// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {SignatureChecker} from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Strings, ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {IFun, SafeTx, SignatureQueue, SQState, MovementType, Movement} from "./interfaces/IFun.sol";
import {ISafe} from "./interfaces/ISafe.sol";
import {ISafeFactory} from "./interfaces/ISafeFactory.sol";
import {SafeFactoryAddresses} from "./info/GnosisSafeFactory.sol";

import {IERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import {EIP712} from "./info/EIP712.sol";
///////////////////////////////////////////////
////////////////////////////////////

/// @title Fungido
/// @author parseb
contract Execution is IERC1155Receiver, EIP712 {
    using Address for address;
    using Strings for string;

    address public RootValueToken;
    address public FoundationAgent;
    IFun public BagBok;
    ISafeFactory SafeFactory;
    address Singleton;

    bytes32 currentTxHash;
    bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;
    bytes4 internal constant EIP1271_MAGIC_VALUE_LEGACY = 0x20c13b0b;

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
    error NoType();
    error AlreadySigned();
    error LenErr();
    error AlreadyInit();
    error OnlyFun();
    error EXEC_SQInvalid();
    error EXEC_NoType();
    error EXEC_NoDescription();
    error EXEC_ZeroLen();
    error EXEC_A0sig();
    error EXEC_OnlyMore();
    error EXEC_OnlySigner();
    error EXEC_SafeExeF();
    error EXEC_InProgress();
    error EXEC_ActionIndexMismatch();

    /// events
    event NewMovementCreated(bytes32 indexed movementHash, uint256 indexed node_);
    event EndpointCreatedForAgent(uint256 indexed nodeid, address endpoint, address agent);
    event BagBokSet(address BBImplementation);

    /// @notice signature by hash
    mapping(bytes32 hash => SignatureQueue SigQueue) getSigQueueByHash;

    /// @notice initialized actions from node [node -> latentActionsOfNode[] | [0] valid start index, prevs. 0]
    mapping(uint256 => bytes32[]) latentActions;

    /// @notice stores node that ownes a particular execution agent authorisation
    mapping(address exeAccount => uint256 endpointOwner) engineOwner;

    /// @notice any one agent is allowed to have only one endpoint
    /// @notice stores agent signatures to prevent double signing  | ( uint256(hash) - uint256(_msgSender()  ) - signer can be simple or composed agent
    mapping(uint256 agentPlusNode => bool) hasEndpointOrInteraction;

    function setBagBook(address bb_) external {
        if (address(BagBok) == address(0)) BagBok = IFun(bb_);
        if (msg.sender == FoundationAgent) BagBok = IFun(bb_);
        emit BagBokSet(bb_);
    }

    constructor(address rootValueToken_) {
        RootValueToken = rootValueToken_;

        SafeFactory = ISafeFactory(SafeFactoryAddresses.factoryAddressForChainId(block.chainid));
        Singleton = SafeFactoryAddresses.getSingletonAddressForChainID(block.chainid);
    }

    function setFoundationAgent(uint256 baseNodeId_) external {
        if (FoundationAgent != address(0)) revert();
        FoundationAgent = this.createEndpointForOwner(address(this), baseNodeId_, address(this));
    }

    function proposeMovement(
        address origin,
        uint256 typeOfMovement,
        uint256 node_,
        uint256 expiresInDays,
        address executingAccount,
        bytes32 descriptionHash,
        SafeTx memory data
    ) external virtual returns (bytes32 movementHash) {
        if (msg.sender != address(BagBok)) revert OnlyFun();

        if (typeOfMovement > 2) revert NoType();
        if (!BagBok.isMember(origin, node_)) revert NotNodeMember();

        if (((typeOfMovement * node_ * expiresInDays) == 0)) revert EmptyUnallowed();
        if (uint256(descriptionHash) == 0) revert EXEC_NoDescription();

        address[] memory members;

        if (executingAccount == address(0)) {
            executingAccount = createNodeEndpoint(origin, node_);

            engineOwner[executingAccount] = node_;

            if (typeOfMovement == 1) {
                members = BagBok.allMembersOf(node_);
                if (members.length == 0) revert NoMembersForNode();
            } else {
                members = new address[](1);
                members[0] = address(this);
            }

            ISafe(executingAccount).setup(
                members,
                members.length / 2 + 1,
                address(0),
                abi.encodePacked(node_ - block.timestamp),
                address(0),
                address(0),
                0,
                (members[0] == address(this) ? executingAccount : members[0])
            );
        } else {
            if (!(engineOwner[executingAccount] == node_)) revert NotExeAccOwner();
        }

        Movement memory M;
        M.initiatior = msg.sender;
        M.viaNode = node_;
        M.descriptionHash = descriptionHash;
        M.txData = data;
        M.exeAccount = executingAccount;
        M.expiresAt = (expiresInDays * 1 days) + block.timestamp;
        M.category = typeOfMovement == 1 ? MovementType.AgentMajority : MovementType.EnergeticMajority;

        movementHash = hashMessage(M);
        latentActions[node_].push(movementHash);

        SignatureQueue memory SQ;
        SQ.state = SQState.Initialized;
        SQ.Action = M;

        if (getSigQueueByHash[movementHash].state != SQState.None) revert AlreadyInitialized();
        getSigQueueByHash[movementHash] = SQ;

        emit NewMovementCreated(movementHash, node_);
    }

    function executeQueue(bytes32 SignatureQueueHash_) public virtual returns (bool s) {
        if (msg.sender != address(BagBok)) revert OnlyFun();

        SignatureQueue memory SQ = validateQueue(SignatureQueueHash_);

        if (SQ.state != SQState.Valid) revert InvalidQueue();
        if (SQ.Action.expiresAt <= block.timestamp) revert ExpiredMovement();

        bytes memory sig = abi.encode(address(this), 65, 0, SignatureQueueHash_.length, SignatureQueueHash_);
        Movement memory M = SQ.Action;

        currentTxHash = keccak256(
            ISafe(SQ.Action.exeAccount).encodeTransactionData(
                M.txData.to,
                M.txData.value,
                M.txData.data,
                M.txData.operation,
                M.txData.safeTxGas,
                M.txData.baseGas,
                M.txData.gasPrice,
                M.txData.gasToken,
                RootValueToken,
                ISafe(SQ.Action.exeAccount).nonce()
            )
        );

        s = ISafe(SQ.Action.exeAccount).execTransaction(
            M.txData.to,
            M.txData.value,
            M.txData.data,
            M.txData.operation,
            M.txData.safeTxGas,
            M.txData.baseGas,
            M.txData.gasPrice,
            M.txData.gasToken,
            RootValueToken,
            sig
        );

        if (!s) revert EXEC_SafeExeF();

        delete currentTxHash;
        SQ.state = SQState.Executed;
        getSigQueueByHash[SignatureQueueHash_] = SQ;
    }

    function submitSignatures(bytes32 sigHash, address[] memory signers, bytes[] memory signatures) external {
        if (msg.sender != address(BagBok)) revert OnlyFun();

        SignatureQueue memory SQ = getSigQueueByHash[sigHash];

        if (signatures.length < SQ.Sigs.length) revert EXEC_OnlyMore();
        if (signers.length * signatures.length == 0) revert EXEC_ZeroLen();
        if (signers.length != signatures.length) revert LenErr();
        uint256 i;
        uint256[] memory validIndexes = new uint256[](signers.length + 1);

        for (i; i < signers.length;) {
            if (signers[i] == address(0)) revert EXEC_A0sig();

            if (hasEndpointOrInteraction[uint256(sigHash) - uint160(signers[i])]) {
                ++i;
                continue;
            }

            if (!(BagBok.isMember(signers[i], SQ.Action.viaNode))) {
                ++i;
                continue;
            }

            if (
                !(SignatureChecker.isValidSignatureNow(signers[i], ECDSA.toEthSignedMessageHash(sigHash), signatures[i]))
            ) {
                validIndexes[i] = 0;
                unchecked {
                    ++i;
                }
                continue;
            }

            i == 0 ? validIndexes[validIndexes.length - 1] = type(uint256).max : validIndexes[i] = i;
            hasEndpointOrInteraction[uint256(sigHash) - uint160(signers[i])] = true;
            unchecked {
                ++i;
            }
        }

        delete i;
        uint256 len;
        for (i; i < validIndexes.length;) {
            if (validIndexes[i] > 0) {
                unchecked {
                    ++len;
                }
            }
            unchecked {
                ++i;
            }
        }

        i = len + SQ.Sigs.length;

        address[] memory newSigners = new address[](i);
        bytes[] memory newSignatures = new bytes[](i);

        delete i;
        delete len;

        for (i; i < validIndexes.length;) {
            uint256 val = validIndexes[i];
            if (val > 0 && val < type(uint256).max) {
                newSigners[len] = signers[val];
                newSignatures[len] = signatures[val];
                unchecked {
                    ++len;
                }
            } else {
                if (val == type(uint256).max) {
                    newSigners[len] = signers[validIndexes[0]];
                    newSignatures[len] = signatures[validIndexes[0]];

                    unchecked {
                        ++len;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        SQ.Signers = newSigners;
        SQ.Sigs = newSignatures;

        getSigQueueByHash[sigHash].Signers = newSigners;
        getSigQueueByHash[sigHash].Sigs = newSignatures;
    }

    function removeSignature(bytes32 sigHash_, uint256 index_, address who_) external {
        if (msg.sender != address(BagBok)) revert OnlyFun();
        SignatureQueue memory SQ = getSigQueueByHash[sigHash_];

        if (SQ.Signers[index_] != who_) revert EXEC_OnlySigner();
        delete SQ.Sigs[index_];
        delete SQ.Signers[index_];
        getSigQueueByHash[sigHash_] = SQ;
        hasEndpointOrInteraction[uint256(sigHash_) - uint160(who_)] = false;
    }

    function removeLatentAction(bytes32 actionHash_, uint256 index) external {
        SignatureQueue memory SQ = getSigQueueByHash[actionHash_];
        if (SQ.Action.expiresAt > block.timestamp) SQ.state = SQState.Stale;
        if (SQ.state == SQState.Initialized || SQ.state == SQState.Valid) revert EXEC_InProgress();
        if (latentActions[SQ.Action.viaNode][index] != actionHash_) revert EXEC_ActionIndexMismatch();
        delete latentActions[SQ.Action.viaNode][index];
        if (uint256(latentActions[SQ.Action.viaNode][0]) > index) latentActions[SQ.Action.viaNode][0] = bytes32(index);
        getSigQueueByHash[actionHash_] = SQ;
    }

    function createEndpointForOwner(address origin, uint256 nodeId_, address owner)
        external
        returns (address endpoint)
    {
        if ((msg.sender != address(BagBok) && owner != address(this))) revert OnlyFun();

        if (!BagBok.isMember(origin, nodeId_) && owner != address(this)) revert NotNodeMember();
        if (hasEndpointOrInteraction[nodeId_ + uint160(bytes20(owner))]) revert AlreadyHasEndpoint();
        hasEndpointOrInteraction[nodeId_ + uint160(bytes20(owner))] = true;

        endpoint = createNodeEndpoint(origin, nodeId_);
        address[] memory members = new address[](1);
        members[0] = owner;

        ISafe(endpoint).setup(
            members, 1, address(0), abi.encodePacked(uint160(owner) - block.timestamp), address(0), address(0), 0, owner
        );
    }

    function createNodeEndpoint(uint256 endpointOwner_) private returns (address endpoint) {
        endpoint = SafeFactory.createProxyWithNonce(Singleton, abi.encodePacked(), (endpointOwner_ - block.timestamp));
    }

    function validateQueue(bytes32 sigHash) internal returns (SignatureQueue memory SQM) {
        SQM = getSigQueueByHash[sigHash];
        if (SQM.Action.expiresAt <= block.timestamp) {
            SQM.state = SQState.Stale;
            getSigQueueByHash[sigHash] = SQM;
        }

        if (!isQueueValid(sigHash)) revert EXEC_SQInvalid();

        SQM.state = SQState.Valid;
        getSigQueueByHash[sigHash] = SQM;
    }

    function isQueueValid(bytes32 sigHash) public view returns (bool) {
        SignatureQueue memory SQM = getSigQueueByHash[sigHash];

        if (SQM.Action.category == MovementType.Revert) return false;
        if (SQM.state == SQState.Valid) return true;
        if (SQM.state == SQState.Stale) return false;
        if (SQM.state != SQState.Initialized) return false;

        uint256 i;
        uint256 power;
        address[] memory signers = SQM.Signers;
        bytes[] memory signatures = SQM.Sigs;

        ///  personalSign @dev @todo make this 712
        bytes32 signedHash = ECDSA.toEthSignedMessageHash(sigHash);

        for (i; i < signatures.length;) {
            if (signers[i] == address(0)) {
                ++i;
                continue;
            }
            if (!SignatureChecker.isValidSignatureNow(signers[i], signedHash, signatures[i])) return false;

            if (SQM.Action.category == MovementType.EnergeticMajority) {
                power += BagBok.balanceOf(signers[i], SQM.Action.viaNode);
            }

            unchecked {
                ++i;
            }
        }

        if (power > 0) return (power > ((BagBok.totalSupply(SQM.Action.viaNode) / 2)));

        return true;
    }

    function createNodeEndpoint(address origin, uint256 endpointOwner_) internal returns (address endpoint) {
        endpoint = createNodeEndpoint(endpointOwner_);
        if (msg.sig == this.createEndpointForOwner.selector || msg.sig == this.setFoundationAgent.selector) {
            engineOwner[endpoint] = uint160(origin);
        } else {
            engineOwner[endpoint] = endpointOwner_;
        }
        BagBok.localizeEndpoint(endpoint, endpointOwner_, origin);
    }

    /// @notice retrieves the endpoint that owns the execution account
    /// @param exeAcc_ execution account for which to retrieve owner
    function exeAccountOwner(address exeAcc_) external view returns (uint256) {
        return engineOwner[exeAcc_];
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4) {
        if (getSigQueueByHash[_hash].state == SQState.Valid) return EIP1271_MAGICVALUE;
    }

    function isValidSignature(bytes memory a, bytes memory b) external view returns (bytes4) {
        if (currentTxHash == keccak256(a)) {
            return EIP1271_MAGIC_VALUE_LEGACY;
        }
    }

    /// @notice retrieves the node or agent  that owns the execution account
    /// @param endpointAddress execution account for which to retrieve owner
    /// @dev in case of user-driven endpoints the returned value is uint160( address of endpoint creator )
    function endpointOwner(address endpointAddress) public view returns (uint256) {
        return engineOwner[endpointAddress];
    }

    function getSigQueue(bytes32 hash_) public view returns (SignatureQueue memory) {
        return getSigQueueByHash[hash_];
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external
        returns (bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function supportsInterface(bytes4 interfaceID) external view override returns (bool) {
        return false;
    }
}
