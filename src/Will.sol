// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {ERC20ASG} from "ERC20ASG/src/ERC20ASG.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {IFun} from "./interfaces/IFun.sol";

/// @title Root Value Token
/// @author Bogdan A. | parseb
/// @notice this is the token of the protocol
contract Will is ERC20ASG {
    address WillWe;
    address Pointer;

    error OnlyPointer();

    constructor(uint256 price_, uint256 pps_, address[] memory initMintAddrs_, uint256[] memory initMintAmts_)
        ERC20ASG("WillWe", "WILL", price_, pps_, initMintAddrs_, initMintAmts_)
    {
        Pointer = msg.sender;
    }

    error TrippinFrFr();
    error InsufficentBalance();
    error OnlyFun();
    error PingF();
    error PayCallF();

    function pingInit() external {
        if (WillWe == address(0) && msg.sender.code.length == 0) {
            WillWe = msg.sender;
        } else {
            revert PingF();
        }
    }

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

        uint256 i;
        bool s = true;
        for (i; i < tokensToRedeem.length;) {
            IERC20 T = IERC20(tokensToRedeem[i]);
            amountToBurn_ = T.balanceOf(address(this));
            if (s) s = s && T.transfer(msg.sender, (amountToBurn_ / shareBurned));
            unchecked {
                ++i;
            }
        }
        if (!s) revert TrippinFrFr();
        (s,) = payable(msg.sender).call{value: address(this).balance / shareBurned}("");
        if (!s) revert PayCallF();
    }

    function simpleBurn(uint256 amountToBurn_) external returns (uint256 amtValReturned) {
        if (balanceOf(msg.sender) < amountToBurn_) revert InsufficentBalance();

        amtValReturned = burn(amountToBurn_);
    }

    function mintFromETH() public payable returns (uint256 howMuchMinted) {
        howMuchMinted = msg.value / currentPrice();
        mint(howMuchMinted);
    }

    function setPointer(address newPointer_) external {
        if (msg.sender != Pointer) revert OnlyPointer();
        Pointer = newPointer_;
    }

    function setWillWe(address willWe_) external {
        if (msg.sender != Pointer) revert OnlyPointer();
        WillWe = willWe_;
    }

    receive() external payable {
        mintFromETH();
    }
}
