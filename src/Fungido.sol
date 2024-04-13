// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "./Membranes.sol";

import "./interfaces/IExecution.sol";
// import {Execution} from "./Execution.sol";
import {IERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IRVT} from "./interfaces/IRVT.sol";

/// @title Fungido
/// @author Bogdan A. | parseb

contract Fungido is ERC1155("fungido.xyz"), Membranes {
    uint256 immutable initTime = block.timestamp;
    address virtualAccount;
    uint256 entityCount;
    address public executionAddress;
    address public RVT;

    /// @notice stores the total supply of each id | id -> supply
    mapping(uint256 => uint256) public totalSupplyOf;

    /// @notice gets children of parent entity given its id | parent => [child...]
    mapping(uint256 => uint256[]) childrenOf;

    /// @notice parent of instance chain | is root if parent is 0
    mapping(uint256 => uint256) parentOf;

    /// @notice parent of instance chain | is root if parent is 0
    mapping(uint256 => uint256) rootOf;

    /// @notice inflation per second | entityID -> [ inflationpersec | last modified] last minted
    mapping(uint256 => uint256[3]) inflSec;

    /// @notice membrane being used by entity | entityID ->  [ membrane id | last Timestamp]
    mapping(uint256 => uint256[2]) inUseMembraneId;

    /// @notice membrane being used by entity
    mapping(uint256 => address[]) members;

    /// @notice root value balances | ERC20 -> Base Value Token (id) -> ERC20 balance
    mapping(address => mapping(uint256 => uint256)) E20bvtBalance;

    /// @notice tax rate on withdrawals as share in base root value token | 100_00 = 0.1% - gas multiplier
    /// @notice default values: 0.01% - x2
    mapping(address => uint256[2]) taxAndGas;
    /// @dev ensure consistency of tax calculation such as enfocing a multiple of 100 on setting

    constructor(address executionAddr) {
        /// default
        taxAndGas[address(0)] = [100_00, 2];
        executionAddress = executionAddr;
        /// @dev
        RVT = IExecution(executionAddr).RootValueToken();

        IRVT(RVT).pingInit();
    }

    ////////////////////////////////////////////////
    //////______ERRORS______///////////////////////

    error Fdo_UniniMembrane();
    error Fdo_BaseOrNonFungible();
    error Fdo_AlreadyMember();
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
    error Internal();
    error ExecutionOnly();
    error ERCGasHog();
    error GasHogOrLightFx();
    error CoreGasTransferFailed();
    error UnallowedAmount();

    ////////////////////////////////////////////////
    //////______EVENTS______///////////////////////

    event NewEntityCreated(uint256 indexed Parent, uint256 indexed newBranch);
    event SpawnedWithMembrane(uint256 indexed newEntity, uint256 usedMembrane);
    event Burned(uint256 Fungible, uint256 Amount, address Who);
    event NewRootRegistered(address indexed ERC20Root);
    event RenouncedMembership(address who, uint256 indexed fromWhere);
    event MintedInflation(uint256 node, uint256 amount);
    event GasUsedWithCost(address who, bytes4 fxSig, uint256 gasCost);
    ////////////////////////////////////////////////
    //////________MODIFIER________/////////////////

    modifier localGas() {
        /// @todo _msgSig()
        uint256 startGas = gasleft();
        _;
        if (address(RVT) != address(0)) {
            uint256 endGas = gasleft();
            uint256 gasUsed = (startGas - endGas) * taxAndGas[address(0)][1];
            // Retrieve the gas price from the transaction
            uint256 gasPrice = tx.gasprice;
            // Calculate the total gas cost in Ether
            uint256 gasCost = gasUsed * gasPrice / 1e18;
            uint256 perUnit = IRVT(RVT).burnReturns(1);

            gasCost = perUnit > gasCost ? 1 ether / (perUnit / gasCost) : gasCost / perUnit;

            endGas = gasleft();
            if (!IRVT(RVT).transferGas(_msgSender(), address(this), gasCost)) revert CoreGasTransferFailed();

            // if (endGas * 2 > gasUsed) revert GasHogOrLightFx();
            emit GasUsedWithCost(_msgSender(), msg.sig, gasCost);
        }
    }

    // function rule() external {
    //             E20bvtBalance[RVT][ spawnBranch( spawnRootBranch(RVT) ) ] = type(uint256).max / 2;
    // }

    ////////////////////////////////////////////////
    //////______EXTERNAL______/////////////////////

    function spawnRootBranch(address fungible20_) public virtual returns (uint256 fID) {
        if (fungible20_.code.length == 0) revert EOA();
        /// @dev constructor call
        fID = toID(fungible20_);

        if (parentOf[fID] == fID) revert RootExists();

        _localizeNode(fID, fID);

        _giveMembership(_msgSender(), fID);

        emit NewRootRegistered(fungible20_);
    }

    function spawnBranch(uint256 fid_) public virtual returns (uint256 newID) {
        if (parentOf[fid_] == 0) revert UnregisteredFungible();
        if (!isMember(_msgSender(), fid_)) revert NotMember();

        unchecked {
            ++entityCount;
        }

        newID = (fid_ - block.timestamp - childrenOf[fid_].length) - entityCount;

        _localizeNode(newID, fid_);

        _giveMembership(_msgSender(), newID);

        emit NewEntityCreated(fid_, newID);
    }

    function spawnBranchWithMembrane(uint256 fid_, uint256 membraneID_) public virtual returns (uint256 newID) {
        if (getMembraneById[membraneID_].tokens.length == 0) revert Fdo_UniniMembrane();
        newID = spawnBranch(fid_);
        inUseMembraneId[newID][0] = membraneID_;
        inUseMembraneId[newID][1] = block.timestamp;

        emit SpawnedWithMembrane(newID, membraneID_);
    }

    function mintMembership(uint256 fid_, address to_) public virtual returns (uint256 mID) {
        if (parentOf[fid_] == 0) revert BranchNotFound();
        mID = membershipID(fid_);
        if (isMember(to_, fid_)) revert Fdo_AlreadyMember();
        if (!gCheck(to_, mID)) revert Unqualified();

        _giveMembership(to_, fid_);
    }

    function mint(uint256 fid_, uint256 amount_) public virtual {
        if (amount_ <= 1) revert UnallowedAmount();
        if (parentOf[fid_] == 0) revert UnregisteredFungible();
        _mint(_msgSender(), fid_, amount_, abi.encodePacked("fungible"));
    }

    ///  @dev _msgSig();
    // function mintFullPath(uint256 fid_, uint256 amount_) public virtual {
    //     uint256[] memory fids = getFidPath(fid_);
    //     uint256 i;
    //     for (i; i < fids.length; ++i;) {
    //         mint(fids[i], amount_);
    //     }
    // }

    /// @notice retrieves token path id array from root to target id
    /// @param fid_ target fid to trace path to from root
    /// @return fid lineage in chronologic order
    function getFidPath(uint256 fid_) public view returns (uint256[] memory fids) {
        uint256 fidCount;
        uint256 parent = 1;
        while (parent >= 1) {
            ++fidCount;
            parent = parentOf[fid_];
        }
        fids = new uint256[](fidCount);

        for (parent; parent < fids.length; ++parent) {
            fids[fids.length - parent - 1] = parentOf[fid_];
            fid_ = parentOf[fid_];
        }
    }

    function burn(uint256 fid_, uint256 amount_) public virtual returns (bool) {
        if (parentOf[fid_] == 0) revert Fdo_BaseOrNonFungible();
        _burn(_msgSender(), fid_, amount_);

        emit Burned(fid_, amount_, _msgSender());
        return true;
    }

    function membershipEnforce(address target, uint256 fid_) public virtual returns (bool s) {
        if (balanceOf(target, fid_) != 1) revert NotMember();
        if (members[fid_].length < 1) revert NoMembership();

        s = !gCheck(target, getMembraneOf(fid_));
        if (s) _burn(target, fid_, 1);
        if (target == _msgSender()) {
            _burn(target, fid_, 1);
            emit RenouncedMembership(target, fid_);
        }
    }

    function mintInflation(uint256 node) public virtual returns (uint256 amount) {
        amount = (block.timestamp - inflSec[node][2]) * inflSec[node][0];
        if (amount == 0) return amount;
        inflSec[node][2] = block.timestamp;

        _mint(address(uint160(node)), node, amount, abi.encodePacked("inflation"));
        emit MintedInflation(node, amount);
    }

    function _giveMembership(address to, uint256 id) private {
        members[membershipID(id)].push(to);

        _mint(to, membershipID(id), 1, abi.encodePacked("membership"));
    }

    /// @dev how dumb 1-10?
    function localizeEndpoint(address endpoint_, uint256 endpointParent_, address endpointOwner_) external {
        // if (_msgSender() != address(this)) revert Internal();
        if (msg.sender != executionAddress) revert ExecutionOnly();
        _localizeNode(toID(endpoint_), endpointParent_);

        if (endpointOwner_ != address(0)) _giveMembership(endpointOwner_, toID(endpoint_));
    }

    function _localizeNode(uint256 newID, uint256 parentId) private {
        rootOf[newID] = rootOf[parentId];
        parentOf[newID] = parentId;
        if (parentId != newID) childrenOf[parentId].push(newID);

        inflSec[newID][0] = 1 gwei;

        /// default inflation rate
        inflSec[newID][2] = block.timestamp;
        /// @redistribution and inflation always couple
    }

    ////////////////////////////////////////////////
    //////________OVERRIDE________/////////////////

    function _afterTokenTransfer(
        address operator,
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

    function _beforeTokenTransfer(
        address operator,
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

        operator;
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

                /// @dev optimise - separate function selector by ord | likely stupid | just make sure to limit operations on membership ids
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
                    _safeTransferFrom(_msgSender(), virtualAccount, parentOf[currentID], currentAmt, "");
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
                    /// taxing

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
                    _safeTransferFrom(virtualAccount, _msgSender(), parentOf[currentID], refundAmount, "");
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

    function _msgSender() internal view virtual override returns (address) {
        if (msg.sender == RVT) return address(this);
        return msg.sender;
    }

    function toAddress(uint256 x) public view returns (address) {
        return x > MAX160 ? address(0) : address(uint160(x));
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
        if (balanceOf(whoabout_, membershipID(whereabout_)) > 0) return true;
    }

    function getMembraneOf(uint256 fid_) public view returns (uint256) {
        return inUseMembraneId[fid_][0];
    }

    function allMembersOf(uint256 fid_) public view returns (address[] memory) {
        return members[membershipID(fid_)];
    }

    function getInUseMembraneOf(uint256 fid_) external view returns (Membrane memory) {
        return getMembraneById[membershipID(fid_)];
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

    // function getRootToken(uint256 fid_) public view returns (address) {
    //     return address(uint160(rootOf[fid_]));
    // }

    function inflationOf(uint256 nodeId) external view returns (uint256) {
        return inflSec[nodeId][0];
    }

    function totalSupply(uint256 nodeId) external view returns (uint256) {
        return totalSupplyOf[nodeId];
    }

    function getUserInteractions(address user_) external view returns (uint256[][2] memory activeBalances) {
        activeBalances[0] = childrenOf[uint160(user_)];
        activeBalances[1] = new uint256[](activeBalances[0].length);
        uint256 i;
        for (i; i < activeBalances[0].length;) {
            activeBalances[1][i] = balanceOf(user_, activeBalances[0][i]);
            unchecked {
                ++i;
            }
        }
    }
}
