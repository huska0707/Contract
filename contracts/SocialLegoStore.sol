// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract onlineStore is KeeperCompatibleInterface, Ownable {
    address keeperRegistryAddress;
    IERC20 socialLegoToken;

    modifier onlyKeeper() {
        require(msg.sender == keeperRegistryAddress); // Ensure that the sender is the Keeper
        _;
    }

    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000;
    address public nextOwner;
    uint256 public massivePurchaseTokenPrice = 0.001 * 10 ** 18;
    uint256 public largePurchaseTokenPrice = 0.00015 * 10 ** 18;
    uint256 public mediumPurchaseTokenPrice = 0.00004 * 10 ** 18;
    uint256 public smallPurchaseTokenPrice = 0.000025 * 10 ** 18;

    constructor(address _keeperRegistryAddress, address _socialLegoToken) {
        keeperRegistryAddress = _keeperRegistryAddress; // Set the Keeper Registry address
        socialLegoToken = IERC20(_socialLegoToken); // Initialize the SocialLego token interface
    }

    function buyMassiveTokens() public payable {
        // how many tokens they want to purchase
        require(
            socialLegoToken.balanceOf(address(this)) >= 1000000 * 10 ** 10,
            "Not Enought Tokens in Contract"
        ); // require this contract to have at least 1,000,000 tokens before executing
        require(
            msg.value >= massivePurchaseTokenPrice,
            "Send the right amount of eth"
        ); // there is a bug when calling the contract through moralis that the msg.value did not equal required even though msg.value was correct.
        socialLegoToken.transfer(msg.sender, 1000000 * 10 ** 18); // send a million tokens.
    }

    function buyLargeTokens() public payable {
        // how many tokens they want to purchase
        require(
            socialLegoToken.balanceOf(address(this)) >= 100000 * 10 ** 10,
            "Not Enought Tokens in Contract"
        ); // require this contract to have at least 1,000,000 tokens before executing
        require(
            msg.value >= largePurchaseTokenPrice,
            "Send the right amount of eth"
        ); // require this contract to have at least 1,000,000 tokens before executing
        socialLegoToken.transfer(msg.sender, 100000 * 10 ** 18); // send 100,0000 tokens.
    }

    function buyMediumTokens() public payable {
        // how many tokens they want to purchase
        require(
            socialLegoToken.balanceOf(address(this)) >= 20000 * 10 ** 10,
            "Not Enought Tokens in Contract"
        ); // require this contract to have at least 1,000,000 tokens before executing
        require(
            msg.value >= mediumPurchaseTokenPrice,
            "Send the right amount of eth"
        ); // require this contract to have at least 1,000,000 tokens before executing
        socialLegoToken.transfer(msg.sender, 20000 * 10 ** 18); // send 20,0000 tokens.
    }

    function buySmallTokens() public payable {
        // how many tokens they want to purchase
        require(
            socialLegoToken.balanceOf(address(this)) >= 10000 * 10 ** 10,
            "Not Enought Tokens in Contract"
        ); // require this contract to have at least 1,000,000 tokens before executing
        require(
            msg.value >= smallPurchaseTokenPrice,
            "Send the right amount of eth"
        ); // require this contract to have at least 1,000,000 tokens before executing
        socialLegoToken.transfer(msg.sender, 10000 * 10 ** 18); // send 10,0000 tokens.
    }
}
