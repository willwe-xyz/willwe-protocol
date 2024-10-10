// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {IERC20ASG} from "./IERC20ASG.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";


//// @notice ERC20GM: Fungible, Uncapped ETH Dutch Auction
/// @author parseb
contract ERC20ASG is ERC20, IERC20ASG {
    //// price amount
    uint256 immutable price;
    uint256 public immutable initTime;
    uint256 public immutable pps;

    ////////////////// Errors

    error ValueMismatch();
    error BurnRefundF();

    ////////////////// External

    //// @notice constructor function instantiates immutable contract instance
    //// @param name_ wanted name of token
    //// @param symbol_ wanted symbol of token
    //// @param price_ wanted starting price in giga-wei
    //// @param pps_ wanted linear price increase in wei per second
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price_,
        uint256 pps_,
        address[] memory initMintAddrs_,
        uint256[] memory initMintAmts_
    ) ERC20(name_, symbol_) {
        price = price_ == 0 ? ((uint256(uint160(bytes20(address(this))) % 10)) + 1 gwei) : price_ * 1 gwei;

        pps = pps_ == 0 ? 1 gwei : pps_;
        initTime = block.timestamp;

        if (initMintAddrs_.length > 0 && initMintAmts_[0] > 0) {
            price_ = 0;
            for (price_; price_ < initMintAddrs_.length;) {
                if (initMintAddrs_[price_] == address(0) || initMintAmts_[price_] == 0) continue;
                _mint(initMintAddrs_[price_], initMintAmts_[price_]);
                unchecked {
                    ++price_;
                }
            }
        }
    }

    //// @inheritdoc IERC20GM
    function mint(uint256 howMany_) public payable {
        if (msg.value < mintCost(howMany_)) revert ValueMismatch();
        _mint(msg.sender, howMany_);
    }

    //// @inheritdoc IERC20GM
    function burn(uint256 howMany_) public override returns (uint256 amtValReturned) {
        amtValReturned = burnReturns(howMany_);
        _burn(msg.sender, howMany_);
        (bool s,) = msg.sender.call{value: amtValReturned}("");
        if (!s) revert BurnRefundF();
    }

    //// @inheritdoc IERC20GM
    function burnTo(uint256 howMany_, address to_) public returns (uint256 amount) {
        amount = burnReturns(howMany_);
        _burn(msg.sender, howMany_);
        (bool s,) = to_.call{value: amount}("");
        if (!s) revert BurnRefundF();
    }

    //// @notice returns current price per unit
    function currentPrice() public view returns (uint256) {
        return (price + (pps * (block.timestamp - initTime)));
    }

    //// @inheritdoc IERC20GM
    function mintCost(uint256 amt_) public view returns (uint256) {
        return currentPrice() * amt_;
    }

    //// @inheritdoc IERC20GM
    function burnReturns(uint256 amt_) public view returns (uint256 rv) {
        if (totalSupply() > 0) rv = amt_ * address(this).balance / totalSupply();
    }
}
