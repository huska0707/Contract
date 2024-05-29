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
    uint256 public massivePurchaseTokenPrice = 0.001 * 10**18;
    uint256 public largePurchaseTokenPrice = 0.00015 * 10**18; 
}
