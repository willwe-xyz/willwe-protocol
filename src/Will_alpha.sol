// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {ERC20ASG} from "ERC20ASG/src/ERC20ASG.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SuperchainERC20} from "./components/SuperchainERC20.sol";
import {IFun} from "./interfaces/IFun.sol";

/// @title Root Value Token with Block-Based Price Protection
/// @notice Implements block-based price updates based purely on total supply
contract Willalpha is SuperchainERC20, ERC20ASG {
    bool private entered;
    
    // Block-based price tracking
    uint256 public lastPrice;
    uint256 public lastPriceBlock;

    constructor(uint256 price_, uint256 pps_, address[] memory initMintAddrs_, uint256[] memory initMintAmts_)
        ERC20ASG("WILL Value Token", "WRVT", price_, pps_, initMintAddrs_, initMintAmts_)
    {
        lastPrice = price_;
        lastPriceBlock = block.number;
    }

    error TransferFailedFor(address failingToken);
    error InsufficentBalance();
    error PayCallF();
    error Reentrant();

    /// @notice Returns the current price, using the cached price for the current block
    function currentPrice() public view override returns (uint256) {
        if (block.number == lastPriceBlock) {
            return lastPrice;
        }
        return totalSupply() / 1 gwei;
    }

    /// @notice Updates and caches the price for the next block
    function updatePrice() internal {
        if (block.number == lastPriceBlock) return;
        lastPrice = totalSupply() / 1 gwei;
        lastPriceBlock = block.number;
    }

    /// @notice Burns tokens and returns proportional assets
    function deconstructBurn(uint256 amountToBurn_, address[] memory tokensToRedeem)
        external
        returns (uint256 shareBurned)
    {
        if (entered) revert Reentrant();
        entered = true;

        if (balanceOf(msg.sender) < amountToBurn_) revert InsufficentBalance();
        
        shareBurned = totalSupply() / amountToBurn_;
        _burn(msg.sender, amountToBurn_);
        updatePrice();

        
        for (uint256 i; i < tokensToRedeem.length;) {
            IERC20 token = IERC20(tokensToRedeem[i]);
            uint256 redeemAmount = token.balanceOf(address(this)) / shareBurned;
            if (!token.transfer(msg.sender, redeemAmount)) revert TransferFailedFor(tokensToRedeem[i]);
            unchecked { ++i; }
        }

        (bool success,) = payable(msg.sender).call{value: address(this).balance / shareBurned}("");
        if (!success) revert PayCallF();

        entered = false;
    }

    /// @notice Mints tokens based on ETH sent
    function mintFromETH() public payable returns (uint256 howMuchMinted) {
        updatePrice();
        howMuchMinted = msg.value / currentPrice();
        mint(howMuchMinted);
    }

    receive() external payable {
        mintFromETH();
    }
}