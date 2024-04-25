// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import "./IFun.sol";

interface IExecution {
    function createEndpointForOwner(address origin, uint256 nodeId_, address owner)
        external
        returns (address endpoint);

    function executeQueue(bytes32 SignatureQueueHash_) external returns (bool s);

    function submitSignatures(bytes32 sigHash, address[] memory signers, bytes[] memory signatures) external;

    function proposeMovement(
        address origin,
        uint256 typeOfMovement,
        uint256 node_,
        uint256 expiresInDays,
        address executingAccount,
        bytes32 descriptionHash,
        SafeTx memory data
    ) external returns (bytes32 movementHash);

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);

    /// @notice retrieves the node or agent  that owns the execution account
    /// @param endpointAddress execution account for which to retrieve owner
    /// @dev in case of user-driven endpoints the returned value is uint160( address of endpoint creator )
    function endpointOwner(address endpointAddress) external view returns (uint256);

    function getSigQueue(bytes32 hash_) external view returns (SignatureQueue memory);

    function setBagBook(address newBB) external;

    function RootValueToken() external view returns (address);

    function isQueueValid(bytes32 sigHash) external view returns (bool);

    function FoundationAgent() external returns (address);

    function setFoundationAgent(address fa_) external;

    //// cleanup functions

    function removeSignature(bytes32 sigHash_, uint256 index_, address who_) external;

    function removeLatentAction(bytes32 actionHash_, uint256 index) external;

}
