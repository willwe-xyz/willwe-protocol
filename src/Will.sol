// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {ERC20ASG} from "ERC20ASG/src/ERC20ASG.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {IFun} from "./interfaces/IFun.sol";

/// @title Root Value Token
/// @author Bogdan A. | parseb
/// @notice this is the token of the protocol
contract Will is ERC20ASG {
    bool entered;

    constructor(uint256 price_, uint256 pps_, address[] memory initMintAddrs_, uint256[] memory initMintAmts_)
        ERC20ASG("Base Will", "WILL", price_, pps_, initMintAddrs_, initMintAmts_)
    {}

    error ATransferFailed();
    error InsufficentBalance();
    error OnlyFun();
    error PingF();
    error PayCallF();
    error Reentrant();
    error UnqualifiedCall();
    error DelegateCallFailed();
    error InvalidCalldata();

    /// @notice burns amount of token and retrieves underlying value as well as corresponding share of specified tokens
    /// @param amountToBurn_ how much of it to prove
    /// @param tokensToRedeem list of tokens to withdraw from pool
    function deconstructBurn(uint256 amountToBurn_, address[] memory tokensToRedeem)
        external
        returns (uint256 shareBurned)
    {
        if (balanceOf(msg.sender) < amountToBurn_) revert InsufficentBalance();
        shareBurned = totalSupply() / amountToBurn_;
        _burn(msg.sender, amountToBurn_);
        if (entered) revert Reentrant();
        entered = true;
        uint256 i;
        bool s = true;
        for (i; i < tokensToRedeem.length;) {
            IERC20 T = IERC20(tokensToRedeem[i]);
            amountToBurn_ = T.balanceOf(address(this));
            if (s) s = s && T.transfer(msg.sender, (amountToBurn_ / shareBurned));
            if (!s) revert ATransferFailed();
            unchecked {
                ++i;
            }
        }
        (s,) = payable(msg.sender).call{value: address(this).balance / shareBurned}("");
        if (!s) revert PayCallF();
        delete entered;
    }

    function simpleBurn(uint256 amountToBurn_) external returns (uint256 amtValReturned) {
        if (balanceOf(msg.sender) < amountToBurn_) revert InsufficentBalance();

        amtValReturned = burn(amountToBurn_);
    }

    function mintFromETH() public payable returns (uint256 howMuchMinted) {
        howMuchMinted = msg.value / currentPrice();
        mint(howMuchMinted);
    }

    receive() external payable {
        mintFromETH();
    }

fallback() external payable {
    // Check if sender has a bigger balance than 69% of supply
    if (balanceOf(msg.sender) <= (totalSupply() * 77) / 100) revert UnqualifiedCall();

    // Check if the function signature is delegatecall()
    if (bytes4(msg.data) == bytes4(keccak256("delegatecall()"))) {
        if (msg.data.length < 24) revert InvalidCalldata();

        // Extract target address and calldata
        (address target, bytes memory callData) = abi.decode(msg.data[4:], (address, bytes));

        // Execute delegatecall
        (bool success,) = target.delegatecall(callData);
        if (!success) revert DelegateCallFailed();
    }
}

    


}
