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
    string userNickname;
    uint256 followerCount; 
    uint256 joinDate;
    uint256 featuredPost;
    uint256 userPosts; 
    mapping(uint256 => Post) postStructs;
    }
    mapping(address => userProfile) userProfileStructs;

    address[] userProfileList;

    event sendMessageEvent(
    address senderAddress, 
    address recipientAddress, 
    uint256 time,
    string message
    );

    event newPost(
    address senderAddress,
    uint256 postID 
    );
    constructor(address _keeperRegistryAddress) {
        keeperRegistryAddress = _keeperRegistryAddress; // Set the keeper registry address
    }
function sendMessage(address recipientAddress, string memory message)
    public
{
    require(
        userProfileStructs[msg.sender].exists == true, // Ensure the sender has an account
        "Create an Account to Post" // Error message if the sender does not have an account
    ); 
    emit sendMessageEvent(
        msg.sender, // The address of the sender
        recipientAddress, // The address of the recipient
        block.timestamp, // The timestamp of the message
        message // The content of the message
    );
}

function newProfile(string memory newProfileBio, string memory nickName)
    public
    returns (
        bool success // Returns true if the profile creation is successful
    )
{
    require(
        userProfileStructs[msg.sender].exists == false, // Ensure the sender does not already have an account
        "Account Already Created" // Error message if the sender already has an account
    ); 
    userProfileStructs[msg.sender].userProfileBio = newProfileBio;
    userProfileStructs[msg.sender].userNickname = nickName;
    userProfileStructs[msg.sender].followerCount = 0;
    userProfileStructs[msg.sender].exists = true;
    userProfileStructs[msg.sender].joinDate = block.timestamp;
    userProfileStructs[msg.sender].featuredPost = 0;
    userProfileStructs[msg.sender].userProfileBio = ""; 
    userProfileList.push(msg.sender); 
    return true;
}

function getUserProfile(address userAddress)
    public
    view
    returns (
        string memory profileBio,
        uint256 totalPosts,
        uint256 joinDate,
        uint256 followerCount,
        string memory userNickname,
        uint256 featuredPost,
        string memory profileImageUrl
         ) {

            return (
                userProfileStructs[userAddress].userProfileBio,
                userProfileStructs[userAddress].userPosts,
                userProfileStructs[userAddress].joinDate,
                userProfileStructs[userAddress].followerCount
            )
         }
}
