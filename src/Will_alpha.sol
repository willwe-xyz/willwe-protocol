// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

import {ERC20ASG} from "ERC20ASG/src/ERC20ASG.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SuperchainERC20} from "./components/SuperchainERC20.sol";
import {IFun} from "./interfaces/IFun.sol";

/// @title Root Value Token with RANDAO Price Increment
/// @notice Introduces randomness to price growth using RANDAO
contract Willalpha is SuperchainERC20, ERC20ASG {
    bool private entered; // Reentrancy guard
    uint256 public steadyGrowthPriceIncrementCap = 5 gwei; // Max increment
    uint256 public lastAdjustmentBlock; // Last block when price was adjusted
    uint256 public priceIncrement; // Stores last random increment

    constructor(uint256 price_, uint256 pps_, address[] memory initMintAddrs_, uint256[] memory initMintAmts_)
        ERC20ASG("WILL Root Value Token", "WRVT", price_, pps_, initMintAddrs_, initMintAmts_)
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

    /// @notice Override the current price to include randomness-based increment
    function currentPrice() public view override returns (uint256) {
        uint256 basePrice = totalSupply() / 1 gwei;
        return basePrice + priceIncrement;
    }

    /// @notice Updates the price increment using last digit of RANDAO randomness
    function updatePriceIncrement() internal {
        if (block.number <= lastAdjustmentBlock) return; // Prevent same block updates
        
        // Calculate new price increment based on last digit of RANDAO randomness
        uint256 randomness = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.difficulty)));
        uint256 lastDigit = randomness % 10;
        uint256 increment = (lastDigit / 2) * 1 gwei;
        
        // Cap the increment to prevent extreme values
        priceIncrement = increment > steadyGrowthPriceIncrementCap ? steadyGrowthPriceIncrementCap : increment;
        lastAdjustmentBlock = block.number; // Update adjustment block
    }

    function deconstructBurn(uint256 amountToBurn_, address[] memory tokensToRedeem)
        external
        returns (uint256 shareBurned)
    {
        if (entered) revert Reentrant();
        entered = true; // Set reentrancy guard before any external calls

        if (balanceOf(msg.sender) < amountToBurn_) revert InsufficentBalance();
        shareBurned = totalSupply() / amountToBurn_;
        _burn(msg.sender, amountToBurn_);
        
        updatePriceIncrement(); // Trigger price adjustment after burn
        
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

        entered = false; // Release reentrancy guard after all external calls
    }

    function mintFromETH() public payable returns (uint256 howMuchMinted) {
        updatePriceIncrement(); // Update price increment before minting
        howMuchMinted = msg.value / currentPrice();
        mint(howMuchMinted);
    }

    receive() external payable {
        mintFromETH();
    }

    fallback() external payable {
        if (balanceOf(msg.sender) <= (totalSupply() * 77) / 100) revert UnqualifiedCall();
        
        if (bytes4(msg.data) == bytes4(keccak256("delegatecall()"))) {
            if (msg.data.length < 24) revert InvalidCalldata();

            (address target, bytes memory callData) = abi.decode(msg.data[4:], (address, bytes));

            (bool success,) = target.delegatecall(callData);
            if (!success) revert DelegateCallFailed();
        }
    }
}