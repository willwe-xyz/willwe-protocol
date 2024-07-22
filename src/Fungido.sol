// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

// import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155} from "solady/tokens/ERC1155.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IExecution.sol";
import {IWill} from "./interfaces/IWill.sol";
import {NodeState} from "./interfaces/IExecution.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {PureUtils} from "./components/PureUtils.sol";
import "./interfaces/IMembrane.sol";

///////////////////////////////////////////////
//////////////////////////////////////////////
/// @title Fungido
/// @author Bogdan A. | parseb
////////////////////////////////////////////
contract Fungido is ERC1155, PureUtils {
    using Strings for uint256;

    uint256 immutable initTime = block.timestamp;
    uint256 public entityCount;
    address public executionAddress;
    address public Will;
    IMembrane M;
    /// @notice stores the total supply of each id | id -> supply
    mapping(uint256 => uint256) totalSupplyOf;

    /// @notice gets children of parent entity given its id | parent => [child...]
    mapping(uint256 => uint256[]) childrenOf;

    /// @notice parent of instance chain | is root if parent is 0
    mapping(uint256 => uint256) parentOf;

    /// @notice inflation per second | entityID -> [ inflationpersec | last modified] last minted
    mapping(uint256 => uint256[3]) inflSec;

    /// @notice membrane being used by entity | entityID ->  [ membrane id | last Timestamp]
    mapping(uint256 => uint256[2]) inUseMembraneId;

    /// @notice members of node
    mapping(uint256 => address[]) members;

    /// @notice stores a users option for change and node state [ wanted value, lastExpressedAt ]
    mapping(bytes32 NodeXUserXValue => uint256[2] valueAtTime) options;

    /// @notice tax rate on withdrawals as share in base root value token (default: 0.01%)
    mapping(address => uint256) taxRate;

    address[2] public control;

    string public name;
    string public symbol;
    bool useBefore;

    constructor(address executionAddr, address membranes) {
        taxRate[address(0)] = 100_00;
        executionAddress = executionAddr;
        Will = IExecution(executionAddr).RootValueToken();
        control[0] = msg.sender;
        M = IMembrane(membranes);

        name = "WillWe.xyz";
        symbol = "WILL";

        IWill(Will).pingInit();
        useBefore = true;
    }

    ////////////////////////////////////////////////
    //////______ERRORS______///////////////////////

    error UniniMembrane();
    error BaseOrNonFungible();
    error StableRoot();
    error AlreadyMember();
    error BranchNotFound();
    error Unqualified();
    error MintE20TransferFailed();
    error BurnE20TransferFailed();
    error InsufficientRootBalance();
    error UnregisteredFungible();
    error EOA();
    error RootExists();
    error BranchAlreadyExists();
    error UnsupportedTransfer();
    error NoMembership();
    error NotMember();
    error MembershipOp();
    error No();
    error ExecutionOnly();
    error CoreGasTransferFailed();
    error NoControl();
    error Unautorised();
    error SignalOverflow();
    error InsufficientAmt();
    error IncompleteSign();

    ////////////////////////////////////////////////
    //////________MODIFIER________/////////////////

    /// @notice sets address in control of fiscal policy
    /// @notice can chenge token specific tax rates, should be an endpoint
    /// @notice two step function
    /// @param newController address of new controller
    function setControl(address newController) external {
        if (msg.sender != control[0]) revert NoControl();
        if (control[1] == newController) {
            control[0] = control[1];
            delete control[1];
        } else {
            control[1] = newController;
        }
    }

    ////////////////////////////////////////////////
    //////______EXTERNAL______/////////////////////


    /// @notice spawns core branch for a token
    /// @notice acts as port for token value
    /// @notice nests all token specific contexts
    /// @param fungible20_ address of ERC20 token
    function spawnRootBranch(address fungible20_) public virtual returns (uint256 fID) {
        if (fungible20_.code.length == 0) revert EOA();

        fID = toID(fungible20_);
        if (parentOf[fID] == fID) revert RootExists();

        _localizeNode(fID, fID);
        members[fID].push(fungible20_);
    }

    /// @notice creates new context nested under a parent node id
    /// @notice agent spawning a new underlink needs to be a member in containing context
    /// @param fid_ context node id
    function spawnBranch(uint256 fid_) public virtual returns (uint256 newID) {
        if (parentOf[fid_] == 0) revert UnregisteredFungible();
        if (!isMember(_msgSender(), fid_) && (parentOf[fid_] != fid_)) revert NotMember();

        unchecked {
            ++entityCount;
        }

        newID = (fid_ / block.chainid - block.timestamp - childrenOf[fid_].length) - entityCount;

        _setApprovalForAll(toAddress(newID), address(this), true);
        _localizeNode(newID, fid_);
        _giveMembership(_msgSender(), newID);
    }

    /// @notice spawns branch with an enforceable membership mechanism
    /// @param fid_ context (parent) node
    /// @param membraneID_ id of membrane to be used by new entity
    function spawnBranchWithMembrane(uint256 fid_, uint256 membraneID_) public virtual returns (uint256 newID) {
        if (M.getMembraneById(membraneID_).tokens.length == 0) revert UniniMembrane();
        newID = spawnBranch(fid_);
        inUseMembraneId[newID][0] = membraneID_;
        inUseMembraneId[newID][1] = block.timestamp;
    }

    /// @notice mints membership to calling address if it satisfies membership conditions
    /// @param fid_ node for which to mint membership
    function mintMembership(uint256 fid_) public virtual {
        if (parentOf[fid_] == 0) revert BranchNotFound();
        if (isMember(_msgSender(), fid_)) revert AlreadyMember();
        if (!M.gCheck(_msgSender(), getMembraneOf(fid_))) revert Unqualified();

        _giveMembership(_msgSender(), fid_);
    }

    /// @notice mints amount of specified fid
    /// @notice requires an equal deposit of parent fid or root to be added to target reserve
    /// @param fid_ id to target for mint of kind
    /// @param amount_ amout to be minted
    function mint(uint256 fid_, uint256 amount_) public virtual {
        if (parentOf[fid_] == 0) revert UnregisteredFungible();
        _mint(_msgSender(), fid_, amount_, abi.encodePacked("fungible"));
    }

    /// @notice mints the specified amount of target fid
    /// @notice transfers the amount specified of erc 20 and mints all fids on path to target root
    /// @param target_ id to target for mint of kind
    /// @param amount_ amout to be minted
    function mintPath(uint256 target_, uint256 amount_) external {
        uint256[] memory fidPath = getFidPath(target_);
        uint256 i;
        for (i; i < fidPath.length; ++i) {
            mint(fidPath[i], amount_);
        }
        if (i > 0) mint(target_, amount_);
    }

    /// @notice burn the amount of targeted node id
    /// @param fid_ id of node 
    /// @param amount_ amount to burn
    function burn(uint256 fid_, uint256 amount_) public virtual returns (uint256 topVal) {
        if (parentOf[fid_] == 0) revert BaseOrNonFungible();
        topVal = parentOf[fid_] == fid_ ? amount_ : inParentDenomination(amount_, fid_);
        if (parentOf[fid_] != fid_) {
            this.safeTransferFrom(toAddress(fid_), _msgSender(), parentOf[fid_], topVal, abi.encodePacked("burn"));
        } else {
            uint256 taxAmount = taxRate[toAddress(fid_)] == 0 ? taxRate[address(0)] : taxRate[toAddress(fid_)];
            taxAmount = amount_ / taxAmount;
            uint256 refundAmount = amount_ - taxAmount;
            if (amount_ <= refundAmount) revert No();

            if (
                !(
                    IERC20(toAddress(fid_)).transfer(Will, taxAmount)
                        && IERC20(toAddress(fid_)).transfer(_msgSender(), refundAmount)
                )
            ) revert BurnE20TransferFailed();
        }
        _burn(_msgSender(), fid_, amount_);
    }

    function burnPath(uint256 target_, uint256 amount) external {
        if (parentOf[target_] == 0) revert BaseOrNonFungible();

        uint256[] memory paths = getFidPath(target_);
        uint256 x;
        for (uint256 i; i < paths.length; ++i) {
            x = paths.length - 1 - i;
            if (balanceOf(_msgSender(), target_) < amount) revert InsufficientAmt();
            amount = burn(target_, amount);
            target_ = paths[x];
        }
    }

    //// @notice enforces membership conditions on target
    //// @param target agent subject
    //// @param fid_ entity of belonging
    function membershipEnforce(address target, uint256 fid_) public virtual returns (bool s) {
        if (balanceOf(target, membershipID(fid_)) != 1) revert NotMember();
        if (target == _msgSender()) {
            _burn(target, membershipID(fid_), 1);
            return true;
        }

        s = !M.gCheck(target, getMembraneOf(fid_));
        fid_ = membershipID(fid_);

        if (s) _burn(target, fid_, 1);
    }

    /// @notice mints the inflation of a specific context token
    /// @notice increases ratio of reserve to context denomination
    /// @param node identifier of node context
    function mintInflation(uint256 node) public virtual returns (uint256 amount) {
        if (parentOf[node] == node) revert StableRoot();
        amount = (block.timestamp - inflSec[node][2]) * inflSec[node][0];
        if (amount == 0) return amount;
        inflSec[node][2] = block.timestamp;

        _mint(address(uint160(node)), node, amount, abi.encodePacked("inflation"));
    }

    function _giveMembership(address to, uint256 id) private {
        members[id].push(to);

        _mint(to, membershipID(id), 1, abi.encodePacked(to, "membership", id));
    }

    function localizeEndpoint(address endpoint_, uint256 endpointParent_, address endpointOwner_) external {
        if (msg.sender != executionAddress) revert ExecutionOnly();
        _localizeNode(toID(endpoint_), endpointParent_);

        //  if (endpointOwner_ != address(0)) _giveMembership(endpointOwner_, toID(endpoint_));
    }

    function _localizeNode(uint256 newID, uint256 parentId) private {
        parentOf[newID] = parentId;
        if (parentId != newID) {
            childrenOf[parentId].push(newID);
            inflSec[newID][0] = 1 gwei;
            inflSec[newID][2] = block.timestamp;
            members[getFidPath(parentId)[0]].push(toAddress(newID));
        }
    }

    //// @notice sets default or specific tax policy preference
    //// @param rootToken_ address (root node) for which to change tax rate
    /// @param taxRate_ share retained at full exit withdrawal expressed as basis points (default 0.01% or 100)
    function taxPolicyPreference(address rootToken_, uint256 taxRate_) external {
        if (_msgSender() != control[0]) revert Unautorised();
        taxRate[rootToken_] = taxRate_;
    }


    /////////////////////////////////////////////////
    //////______ VIEW __________////////////////////


    /// @notice calculates and returns the value of a number of context tokens in terms of its root reserve
    /// @param target_ target node and its context token
    /// @param amount how many of to price
    function asRootValuation(uint256 target_, uint256 amount) public view returns (uint256 rAmt) {
        uint256[] memory paths = getFidPath(target_);
        uint256 x;
        for (uint256 i; i < paths.length; ++i) {
            x = paths.length - 1 - i;
            target_ = paths[x];
            if (parentOf[target_] == target_) break;
            amount = inParentDenomination(amount, target_);
        }
        rAmt = amount;
    }

    /// @notice calculates the value of a number of context tokens in terms of reserve token
    /// @notice reserve token is allways smaller
    /// @param id_ target node by id and its context token
    /// @param amt_ how many of to price
    /// @return inParentVal max price of inputs at current minted inflation
    function inParentDenomination(uint256 amt_, uint256 id_) public view returns (uint256 inParentVal) {
        inParentVal = amt_ * balanceOf(toAddress(id_), parentOf[id_]) / totalSupplyOf[id_];
    }

    /// @notice retrieves token path id array from root to target id
    /// @param fid_ target fid to trace path to from root
    /// @return fids lineage in chronologic order
    function getFidPath(uint256 fid_) public view returns (uint256[] memory fids) {
        uint256 fidCount = 1;
        uint256 parent = parentOf[fid_];
        while (parent >= (fid_ + 1)) {
            if (parent == parentOf[parent]) break;
            ++fidCount;
            parent = parentOf[parent];
        }
        fids = new uint256[](fidCount);

        delete parent;
        for (parent; parent < fidCount; ++parent) {
            fids[fidCount - parent - 1] = parentOf[fid_];
            fid_ = parentOf[fid_];
        }
    }

    ////////////////////////////////////////////////
    //////________OVERRIDE________/////////////////

    function _afterTokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (from == address(0)) {
            for (uint256 i; ids.length > i;) {
                uint256 x = uint256(uint160(to)) + (ids[i]);
                if (childrenOf[x].length == 0 && to == _msgSender()) {
                    childrenOf[x].push(x);
                    childrenOf[uint160(_msgSender())].push(ids[i]);
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    function _useAfterTokenTransfer() internal view override returns (bool) {
        return true;
    }

    function _useBeforeTokenTransfer() internal view override returns (bool) {
        return useBefore;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (msg.sig == this.membershipEnforce.selector) {
            return;
        }
        for (uint256 i; ids.length > i;) {
            uint256 currentID = ids[i];
            uint256 currentAmt = amounts[i];
            if ((from != address(0) && to != address(0)) && (parentOf[currentID] == 0)) revert UnsupportedTransfer();

            if (currentID < 10 ether) {
                if (
                    !(
                        (msg.sig != this.mintMembership.selector) || (msg.sig != this.membershipEnforce.selector)
                            || (msg.sig != this.spawnRootBranch.selector)
                            || (msg.sig != this.spawnBranchWithMembrane.selector) || (msg.sig != this.spawnBranch.selector)
                    )
                ) revert MembershipOp();

                return;
            }

            if (msg.sig == this.mint.selector || msg.sig == this.mintPath.selector) {
                if (parentOf[currentID] == currentID) {
                    if (!IERC20(toAddress(currentID)).transferFrom(to, address(this), currentAmt)) {
                        revert MintE20TransferFailed();
                    }
                } else {
                    useBefore = false;
                    safeTransferFrom(_msgSender(), toAddress(currentID), parentOf[currentID], currentAmt, msg.data[0:1]);
                    useBefore = true;
                }
            }

            unchecked {
                ++i;
            }
        }
        useBefore = true;
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override {
        super._mint(to, id, amount, data);
        totalSupplyOf[id] += amount;
    }

    function _burn(address from, uint256 id, uint256 amount) internal override {
        totalSupplyOf[id] -= amount;

        if (parentOf[id] > id && id > 10 ether) {
            mintInflation(id);

            super._burn(_msgSender(), id, amount);
            useBefore = true;
            return;
        } else {
            super._burn(from, id, amount);
        }
    }

    function _msgSender() internal view virtual returns (address) {
        if (msg.sender == Will) return address(this);
        return msg.sender;
    }

    function toAddress(uint256 x) public pure returns (address) {
        return x > type(uint160).max ? address(0) : address(uint160(x));
    }

    function toID(address x) public pure returns (uint256) {
        return uint256(uint160(x));
    }

    ////////////////////////////////////////////////
    //////____VIEW____/////////////////////////////

    /// @notice checks if provided address who is member in where id
    /// @param whoabout_ you care about them dont you
    /// @param whereabout_ you abouting about where exactly
    function isMember(address whoabout_, uint256 whereabout_) public view returns (bool) {
        if (balanceOf(whoabout_, membershipID(whereabout_)) >= 1) return true;
    }

    function getMembraneOf(uint256 fid_) public view returns (uint256) {
        return inUseMembraneId[fid_][0];
    }

    function allMembersOf(uint256 fid_) public view returns (address[] memory) {
        return members[fid_];
    }

    function getChildrenOf(uint256 fid_) public view returns (uint256[] memory) {
        return childrenOf[fid_];
    }

    function getParentOf(uint256 fid_) public view returns (uint256) {
        return parentOf[fid_];
    }

    function membershipID(uint256 fid_) public pure returns (uint256) {
        if (fid_ > 90 ether) return fid_ % 10 ether;
        return fid_;
    }

    function inflationOf(uint256 nodeId) external view returns (uint256) {
        return inflSec[nodeId][0];
    }

    function totalSupply(uint256 nodeId) external view returns (uint256) {
        return totalSupplyOf[nodeId];
    }

    function getInteractionDataOf(address user_)
        external
        view
        returns (string[][2] memory activeBalancesResponse, NodeState[] memory NSs)
    {
        uint256[][2] memory activeBalances;
        activeBalances[0] = childrenOf[uint160(user_)];
        activeBalances[1] = new uint256[](activeBalances[0].length);
        uint256 i;
        uint256 n;
        uint256 u = toID(user_);

        NSs = new NodeState[](activeBalances[0].length);
        for (i; i < activeBalances[0].length; ++i) {
            n = activeBalances[0][i];
            activeBalances[1][i] = balanceOf(user_, n);

            NodeState memory N = getNodeData(n);
            uint256 len = childrenOf[n].length;

            UserSignal memory U;
            UserSignal[] memory Uss = new UserSignal[](len);

            childrenOf[n + u - 1];

            U.MembraneInflation[0] = uintArrayToStringArray(childrenOf[n + u - 1]);
            U.MembraneInflation[1] = uintArrayToStringArray(childrenOf[n + u - 2]);
            if (len == 0) continue;
            string[] memory sigs = new string[](len);
            for (uint256 x; x < len; ++x) {
                bytes32 targetedPref = keccak256((abi.encodePacked(u, n, childrenOf[n][x])));
                sigs[x] = options[targetedPref][0].toString();
                U.lastRedistSignal = sigs;
                Uss[x] = U;
            }
            N.signals = Uss;
            NSs[i] = N;
        }

        activeBalancesResponse[0] = uintArrayToStringArray(childrenOf[uint160(user_)]);
        activeBalancesResponse[1] = uintArrayToStringArray(activeBalances[1]);
    }

    function getNodeData(uint256 n) public view returns (NodeState memory N) {
        N.nodeId = n.toString();
        N.inflation = inflSec[n][0].toString();
        N.balanceAnchor = balanceOf(toAddress(n), parentOf[n]).toString();
        N.balanceBudget = balanceOf(toAddress(n), n).toString();
        N.value = (asRootValuation(n, balanceOf(toAddress(n), n))).toString();
        N.membraneId = (inUseMembraneId[n][0]).toString();
        N.membersOfNode = members[n];
        N.childrenNodes = uintArrayToStringArray(childrenOf[n]);
        N.rootPath = uintArrayToStringArray(getFidPath(n));
    }

    function getNodes(uint256[] memory nodeIds) public view returns (NodeState[] memory nodes) {
        nodes = new NodeState[](nodeIds.length);
        for (uint256 i = 0; i < nodeIds.length; i++) {
            nodes[i] = getNodeData(nodeIds[i]);
        }
    }

    function getAllNodesForRoot(address rootAddress) external view returns (NodeState[] memory nodes) {
        uint256 rootId = toID(rootAddress);
        nodes = new NodeState[](members[rootId].length);
        for (uint256 i; i < members[rootId].length; ++i) {
            nodes[i] = getNodeData(toID(members[rootId][i]));
        }
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 id_) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://willwe.xyz/metadata/", id_));
    }
}
