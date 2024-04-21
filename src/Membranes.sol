// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import "./interfaces/IMembrane.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Membrane
/// @author parseb
contract Membranes is IMembrane {
    mapping(uint256 => Membrane) membraneById;

    error membraneNotFound();
    error Membrane__EmptyFieldOnMembraneCreation();

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
        id = uint256(keccak256(abi.encode(M))) % type(uint176).max;
        membraneById[id] = M;
    }

    //////////////////////////////////////////////////
    //////////########## Internal

    /// @notice checks if given address respects the conditions of the specified membrane
    /// @param who_: address of agent to be checked
    /// @param membraneID_: conditions
    function gCheck(address who_, uint256 membraneID_) public view returns (bool s) {
        Membrane memory M = membraneById[membraneID_];
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

    function getMembraneById(uint256 id_) public view returns (Membrane memory) {
        return membraneById[id_];
    }
}
