// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./interfaces/IMembrane.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Fungido
/// @author Bogdan Arsene | parseb
abstract contract Membranes is IMembrane {
    mapping(uint256 => Membrane) getMembraneById;

    error membraneNotFound();
    error Membrane__EmptyFieldOnMembraneCreation();

    event CreatedMembrane(uint256 id, string metadata);
    event ChangedMembrane(address they, uint256 membrane);
    event gCheckKick(address indexed who);

    uint256 immutable Y_SEC = 525600;
    uint256 immutable MAX160 = type(uint160).max;
    uint256 immutable MAX176 = type(uint176).max;

    // bytes immutable CONTINUE = bytes("continue");

    /// @inheritdoc IMembrane
    function createMembrane(address[] memory tokens_, uint256[] memory balances_, string memory meta_)
        public
        virtual
        returns (uint256 id)
    {
        if (!((tokens_.length / balances_.length) * bytes(meta_).length >= 1)) {
            revert Membrane__EmptyFieldOnMembraneCreation();
        }
        Membrane memory M;
        M.tokens = tokens_;
        M.balances = balances_;
        M.meta = meta_;
        id = uint256(keccak256(abi.encode(M))) % MAX176;
        getMembraneById[id] = M;

        emit CreatedMembrane(id, meta_);
    }

    //////////////////////////////////////////////////
    //////////########## Internal

    /// @notice checks if given address respects the conditions of the specified membrane
    /// @param who_: address of agent to be checked
    /// @param membraneID_: conditions
    function gCheck(address who_, uint256 membraneID_) public view returns (bool s) {
        Membrane memory M = getMembraneById[membraneID_];
        membraneID_ = 0;
        s = true;
        for (membraneID_; membraneID_ < M.tokens.length;) {
            if (
                M.balances[membraneID_] == 0 && M.tokens[membraneID_] != address(0)
                    && (IERC20(M.tokens[membraneID_]).balanceOf(who_) == 0)
            ) continue;
            /// @dev  "not member in"
            s = s && (IERC20(M.tokens[membraneID_]).balanceOf(who_) >= M.balances[membraneID_]);
            if (!s) return false;
            unchecked {
                ++membraneID_;
            }
        }
    }
}
