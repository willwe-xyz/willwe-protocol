// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

struct Membrane {
    address[] tokens;
    uint256[] balances;
    string meta;
    uint256 createdAt;
}

interface IMembrane {
    /// @notice creates membrane. Used to control and define.
    /// @notice To be read and understood as: Givent this membrane, of each of the tokens_[x], the user needs at least balances_[x].
    /// @param tokens_ ERC20 or ERC721 token addresses array. Each is used as a constituent item of the membrane and condition for
    /// @param tokens_ at [x] can e a user address that is whitelisted or blacklisted. for blacklist set balance to 0. for whitelist uint256(uint160(address of user))
    /// @param tokens_ at [x] if it is willwe address the balancce_ at [x] is the node id of which the user is required to already be a member of
    /// @param tokens_ belonging or not. Membership is established by a chain of binary claims whereby
    /// @param tokens_ the balance of address checked needs to satisfy all balances_ of all tokens_ stated as benchmark for belonging
    /// @param balances_ amounts required of each of tokens_. The order of required balances needs to map to token addresses.
    /// @param meta_ anything you want. Preferably stable CID for reaching aditional metadata such as an IPFS hash of type string.
    function createMembrane(address[] memory tokens_, uint256[] memory balances_, string memory meta_)
        external
        returns (uint256);

    /// @notice checks if given address respects the conditions of the specified membrane
    /// @param who_: address of agent to be checked
    /// @param membraneID_: conditions
    function gCheck(address who_, uint256 membraneID_) external view returns (bool s);

    function getMembraneById(uint256 id_) external view returns (Membrane memory);

    function setInitWillWe() external;
}
