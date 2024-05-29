// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract SocialLego is KeeperCompatibleInterface, Ownable {
    address keeperRegistryAddress;
    modifier onlyKeeper() {
        require(msg.sender == keeperRegistryAddress);
        _;
    }

    uint256 public lastCheckIn = block.timestamp;

    uint256 public checkInTimeInterval = 864000;

    address public nextOwner;
    struct Comment {
        address commenter;
        string message;
        uint256 timestamp; 
    }

    struct Post {
        uint256 numberOfLikes; 
        uint256 timestamp;
        string message;
        string url; 
         uint256 totalComments; 
         mappig (uint256 => Comment) commentStructs;
    }

    struct userProfile { 
    bool exists;
    address userAddress;
    string profileImageUrl;
    string userProfileBio;
    }
}
