// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {ERC20ASG} from "ERC20ASG/src/ERC20ASG.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {IFun} from "./interfaces/IFun.sol";

/// @title Fungido
/// @author Bogdan A. | parseb
/// @notice this is the token of the protocol
contract Fungo is ERC20ASG {
    address FungidoAddr;

    constructor(uint256 price_, uint256 pps_, address[] memory initMintAddrs_, uint256[] memory initMintAmts_)
        ERC20ASG("Root Value Token", "RVT", price_, pps_, initMintAddrs_, initMintAmts_)
    {}

    error TrippinFrFr();
    error InsufficentBalance();

    function pingInit() external {
        if (FungidoAddr == address(0) && msg.sender.code.length == 0) {
            FungidoAddr = msg.sender;
        } else {
            revert();
        }
    }

    /// @notice burns amount of token and retrieves underlying value as well as corresponding share of specified tokens
    ///
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
        payable(msg.sender).call{value: address(this).balance / shareBurned};
    }

    function simpleBurn(uint256 amountToBurn_) external returns (uint256 amtValReturned) {
        if (balanceOf(msg.sender) < amountToBurn_) revert InsufficentBalance();

        amtValReturned = burn(amountToBurn_);
    }

    function transferGas(address from, address to, uint256 amount) public returns (bool) {
        if (to == FungidoAddr && msg.sender == FungidoAddr) _approve(from, to, amount);
        transferFrom(from, to, amount);
        IFun(FungidoAddr).mint(uint256(uint160(FungidoAddr)), amount);
    }
}
