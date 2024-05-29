// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract NFTMint is
    ERC721,
    VRFConsumerBase,
    Ownable,
    KeeperCompatibleInterface
{
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public mintFee = 0.002 * 10 ** 18;
    uint256 public randomResult;

    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000;
    address public nextOwner;

    address keeperRegistryAddress;
    address gameAddress;

    modifier onlyGame() {
        require(msg.sender == gameAddress);
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeperRegistryAddress);
        _;
    }

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _keeperRegistryAddress
    ) VRFConsumerBase(_vrfCoordinator, _link) ERC721("BreakInNFTs", "BIN") {
        keyHash = _keyHash;
        fee = _fee; // Fee varies by network

        keeperRegistryAddress = _keeperRegistryAddress;
    }

    struct NFTCharacter {
        string name;
        uint256 born;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        uint256 characterID;
    }

    struct mintableNFTCharacter {
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        string imageURI;
        string name;
        string description;
    }
    uint256 public totalMintableCharacters;

    mapping(uint256 => mintableNFTCharacter) public mintableNFTCharacterStruct;
    mapping(bytes32 => NFTCharacter) NFTCharacterStruct;
    mapping(bytes32 => address) requestToSender;

    NFTCharacter[] public characters;

    function addCharacterOne(
        uint256 health,
        string memory imageURI,
        string memory name,
        string memory description
    ) public {
        uint256 characterID = totalMintableCharacters;
        mintableNFTCharacterStruct[characterID].health = health; 
    }
}
