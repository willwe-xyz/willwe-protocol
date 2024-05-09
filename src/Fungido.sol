// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

// import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155} from "solady/tokens/ERC1155.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IExecution.sol";
import {IRVT} from "./interfaces/IRVT.sol";
import {NodeState} from "./interfaces/IFun.sol";
import "./interfaces/IMembrane.sol";

///////////////////////////////////////////////
////////////////////////////////////

/// @title Fungido
/// @author Bogdan A. | parseb

contract Fungido is ERC1155 {
    uint256 immutable initTime = block.timestamp;
    address virtualAccount;
    uint256 public entityCount;
    address public executionAddress;
    address public RVT;
    IMembrane M;
    /// @notice stores the total supply of each id | id -> supply
    mapping(uint256 => uint256) public totalSupplyOf;

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

    /// @notice root value balances | ERC20 -> Base Value Token (id) -> ERC20 balance
    mapping(address => mapping(uint256 => uint256)) E20bvtBalance;

    /// @notice tax rate on withdrawals as share in base root value token | 100_00 = 0.1% - gas multiplier
    /// @notice default values: 0.01% - x2
    mapping(address => uint256[2]) taxAndGas;
    /// @dev ensure consistency of tax calculation such as enfocing a multiple of 100 on setting

    address[2] public control;

    string public name;
    string public symbol;

    constructor(address executionAddr, address membranes) {
        /// default
        taxAndGas[address(0)] = [100_00, 2];
        executionAddress = executionAddr;
        /// @dev
        RVT = IExecution(executionAddr).RootValueToken();
        control[0] = msg.sender;
        M = IMembrane(membranes);

        name = "BagBok.com";
        symbol = "BagBok";

        IRVT(RVT).pingInit();
    }

    ////////////////////////////////////////////////
    //////______ERRORS______///////////////////////

    error UniniMembrane();
    error BaseOrNonFungible();
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

    ////////////////////////////////////////////////
    //////________MODIFIER________/////////////////

    modifier localGas() {
        if (!((control[0] == control[1]) && (address(RVT) != address(0)))) {
            _;
        } else {
            uint256 startGas = gasleft();
            _;
            uint256 endGas = gasleft();
            uint256 multiplier = taxAndGas[_msgSender()][1] == 0 ? taxAndGas[address(0)][1] : taxAndGas[_msgSender()][1];
            uint256 gasUsed = (startGas - endGas) * multiplier;
            uint256 gasPrice = tx.gasprice;
            uint256 gasCost = gasUsed * gasPrice / 1e18;
            uint256 perUnit = IRVT(RVT).burnReturns(1);

            gasCost = perUnit > gasCost ? 1 ether / (perUnit / gasCost) : gasCost / perUnit;
            endGas = gasleft();

            if (!IRVT(RVT).transferGas(_msgSender(), address(this), gasCost)) revert CoreGasTransferFailed();
        }
    }

    function setControl(address newController) external {
        if (msg.sender != control[0]) revert NoControl();
        if (control[1] == newController) {
            control[1] = address(0);
            control[0] = address(0);
        }
        control[0] == newController ? control[1] = newController : control[0] = newController;
    }

    ////////////////////////////////////////////////
    //////______EXTERNAL______/////////////////////

    function spawnRootBranch(address fungible20_) public virtual localGas returns (uint256 fID) {
        if (fungible20_.code.length == 0) revert EOA();
        /// @dev constructor call
        fID = toID(fungible20_);

        if (parentOf[fID] == fID) revert RootExists();

        _localizeNode(fID, fID);

        _giveMembership(_msgSender(), fID);
    }

    function spawnBranch(uint256 fid_) public virtual localGas returns (uint256 newID) {
        if (parentOf[fid_] == 0) revert UnregisteredFungible();
        if (!isMember(_msgSender(), fid_)) revert NotMember();

        unchecked {
            ++entityCount;
        }

        newID = (fid_ - block.timestamp - childrenOf[fid_].length) - entityCount;

        _localizeNode(newID, fid_);
        _giveMembership(_msgSender(), newID);
    }

    function spawnBranchWithMembrane(uint256 fid_, uint256 membraneID_)
        public
        virtual
        localGas
        returns (uint256 newID)
    {
        if (M.getMembraneById(membraneID_).tokens.length == 0) revert UniniMembrane();
        newID = spawnBranch(fid_);
        inUseMembraneId[newID][0] = membraneID_;
        inUseMembraneId[newID][1] = block.timestamp;
    }

    function mintMembership(uint256 fid_, address to_) public virtual localGas {
        if (parentOf[fid_] == 0) revert BranchNotFound();
        if (isMember(to_, fid_)) revert AlreadyMember();
        if (!M.gCheck(to_, membershipID(fid_))) revert Unqualified();

        _giveMembership(to_, fid_);
    }

    function mint(uint256 fid_, uint256 amount_) public virtual localGas {
        if (parentOf[fid_] == 0) revert UnregisteredFungible();
        _mint(_msgSender(), fid_, amount_, abi.encodePacked(fid_, "fungible", amount_));
    }

    function mintPath(uint256 target_, uint256 amount) external {
        uint256[] memory fidPath = getFidPath(target_);
        for (uint256 i; i < fidPath.length; ++i) {
            mint(fidPath[i], amount);
        }
    }

    /// @notice retrieves token path id array from root to target id
    /// @param fid_ target fid to trace path to from root
    /// @return fids lineage in chronologic order
    function getFidPath(uint256 fid_) public view returns (uint256[] memory fids) {
        uint256 fidCount;
        uint256 parent = parentOf[fid_];
        while (parent >= 1) {
            ++fidCount;
            if (parent == parentOf[parent]) break;
            parent = parentOf[parent];
        }
        fids = new uint256[](fidCount);

        delete parent;
        for (parent; parent < fids.length; ++parent) {
            fids[fids.length - parent - 1] = parentOf[fid_];
            fid_ = parentOf[fid_];
        }
    }

    function burn(uint256 fid_, uint256 amount_) public virtual {
        if (parentOf[fid_] == 0) revert BaseOrNonFungible();
        _burn(_msgSender(), fid_, amount_);
    }

    //// @notice enforces membership conditions on target
    //// @param target agent subject
    //// @param fid_ entity of belonging
    function membershipEnforce(address target, uint256 fid_) public virtual returns (bool s) {
        if (balanceOf(target, fid_) != 1) revert NotMember();
        if (members[fid_].length < 1) revert NoMembership();

        s = !M.gCheck(target, getMembraneOf(fid_));
        if (s) _burn(target, fid_, 1);
        if (target == _msgSender()) {
            _burn(target, fid_, 1);
        }
    }

    function mintInflation(uint256 node) public virtual returns (uint256 amount) {
        amount = (block.timestamp - inflSec[node][2]) * inflSec[node][0];
        if (amount == 0) return amount;
        inflSec[node][2] = block.timestamp;

        _mint(address(uint160(node)), node, amount, abi.encodePacked(node, "inflation", amount));
    }

    function _giveMembership(address to, uint256 id) private {
        members[membershipID(id)].push(to);

        _mint(to, membershipID(id), 1, abi.encodePacked(to, "membership", id));
    }

    function localizeEndpoint(address endpoint_, uint256 endpointParent_, address endpointOwner_) external {
        if (msg.sender != executionAddress) revert ExecutionOnly();
        _localizeNode(toID(endpoint_), endpointParent_);

        if (endpointOwner_ != address(0)) _giveMembership(endpointOwner_, toID(endpoint_));
    }

    function _localizeNode(uint256 newID, uint256 parentId) private {
        parentOf[newID] = parentId;
        if (parentId != newID) childrenOf[parentId].push(newID);
        inflSec[newID][0] = 1 gwei;
        inflSec[newID][2] = block.timestamp;
    }

    function taxPolicyPreference(address rootToken_, uint256 taxRate_) external {
        if (_msgSender() != control[0]) revert Unautorised();
        taxAndGas[rootToken_][0] = taxRate_;
    }

    function gasMultiplier(address sender, uint256 multiplier_) external {
        if (_msgSender() != control[0]) revert Unautorised();
        taxAndGas[sender][1] = multiplier_;
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
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (virtualAccount != address(0)) return;
        if (msg.sig == this.membershipEnforce.selector) {
            return;
        }

        if (from != address(0) && to != address(0)) revert UnsupportedTransfer();
        for (uint256 i; ids.length > i;) {
            uint256 currentID = ids[i];
            uint256 currentAmt = amounts[i];

            if (currentID < 10 ether) {
                if (
                    !(
                        (msg.sig != this.mintMembership.selector) || (msg.sig != this.membershipEnforce.selector)
                            || (msg.sig != this.spawnRootBranch.selector)
                            || (msg.sig != this.spawnBranchWithMembrane.selector) || (msg.sig != this.spawnBranch.selector)
                    )
                ) revert MembershipOp();
                totalSupplyOf[currentID] = members[currentID].length;

                return;
            }

            if (msg.sig == this.mint.selector) {
                if (parentOf[currentID] == currentID) {
                    E20bvtBalance[toAddress(parentOf[currentID])][currentID] += currentAmt;

                    if (!IERC20(toAddress(parentOf[currentID])).transferFrom(_msgSender(), address(this), currentAmt)) {
                        revert MintE20TransferFailed();
                    }
                } else {
                    virtualAccount = toAddress(currentID);
                    safeTransferFrom(_msgSender(), virtualAccount, parentOf[currentID], currentAmt, msg.data[0:1]);
                    delete virtualAccount;
                }
            }

            if (msg.sig == this.burn.selector) {
                uint256 refundAmount;
                address token20 = toAddress(parentOf[currentID]);
                if (parentOf[currentID] == currentID) {
                    if (E20bvtBalance[token20][currentID] < currentAmt) {
                        revert InsufficientRootBalance();
                    }
                    refundAmount = currentAmt * totalSupplyOf[currentID] / E20bvtBalance[token20][currentID];

                    if (currentAmt < refundAmount) revert No();
                    E20bvtBalance[token20][currentID] -= currentAmt;

                    uint256 taxAmount = taxAndGas[token20][0] == 0 ? taxAndGas[address(0)][0] : taxAndGas[token20][0];
                    taxAmount = refundAmount / taxAmount;
                    refundAmount = refundAmount - taxAmount;

                    IERC20(token20).transfer(RVT, taxAmount);

                    if (!IERC20(token20).transfer(_msgSender(), refundAmount)) {
                        revert BurnE20TransferFailed();
                    }
                } else {
                    refundAmount = currentAmt * totalSupplyOf[currentID] / totalSupplyOf[parentOf[currentID]];
                    virtualAccount = toAddress(currentID);
                    safeTransferFrom(virtualAccount, _msgSender(), parentOf[currentID], refundAmount, msg.data[0:1]);
                    delete virtualAccount;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override {
        super._mint(to, id, amount, data);
        totalSupplyOf[id] += amount;
    }

    function _burn(address from, uint256 id, uint256 amount) internal override {
        super._burn(from, id, amount);
        totalSupplyOf[id] -= amount;
    }

    function _msgSender() internal view virtual returns (address) {
        if (msg.sender == RVT) return address(this);
        return msg.sender;
    }

    function toAddress(uint256 x) public view returns (address) {
        return x > type(uint160).max ? address(0) : address(uint160(x));
    }

    function toID(address x) public view returns (uint256) {
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
        return members[membershipID(fid_)];
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

    //     const BBbalances = await BB.getUserInteractions(userAddr);
    //   BBbalances[0].forEach(async (X) => {
    //   let nodeId:string = X.toString();
    //   //// ignores membrane ids - extra call - @todo pack in one multicall or create util contract
    //   let parent: string = await BB.getParentOf(nodeId);
    //   if (nodeId.length > 20 && parent != "0") {
    //     let nodeAsAddress = await BB.toAddress(nodeId);
    //     let membrane: string = await BB.getMembraneOf(nodeId);
    //     let isMember: boolean = await BB.isMember(userAddr,nodeId);
    //     let inflation: string = await BB.inflationOf(nodeId);
    //     let balanceA: string = await BB.balanceOf(nodeAsAddress, parent);
    //     let balanceB: string = await BB.balanceOf(nodeAsAddress, nodeId);
    //     let membersOfNode: string[] = parent != "0" ? await BB.allMembersOf(nodeId) : [];

    function getInteractionDataOf(address user_)
        external
        view
        returns (uint256[][2] memory activeBalances, NodeState[] memory)
    {
        activeBalances[0] = childrenOf[uint160(user_)];
        activeBalances[1] = new uint256[](activeBalances[0].length);
        uint256 i;
        uint256 n;

        NodeState[] memory NSs = new NodeState[](activeBalances[0].length);
        for (i; i < activeBalances[0].length;) {
            n = activeBalances[0][i];
            activeBalances[1][i] = balanceOf(user_, n);
            NodeState memory N;
            N.nodeId = n;
            N.inflation = inflSec[n][0];
            N.balanceAnchor = balanceOf(toAddress(n), parentOf[n]);
            N.balanceBudget = balanceOf(toAddress(n), n);
            N.membraneId = inUseMembraneId[n][0];
            N.membersOfNode = members[n];
            N.childrenNodes = childrenOf[n];

            NSs[i] = N;

            unchecked {
                ++i;
            }
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
        return string(abi.encodePacked("https://bagbok.com/node-meta/", abi.encode(id_)));
    }
}
