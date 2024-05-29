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
        mintableNFTCharacterStruct[characterID].agility = 250;
        mintableNFTCharacterStruct[characterID].strength = 250;
        mintableNFTCharacterStruct[characterID].sneak = 500;
        mintableNFTCharacterStruct[characterID].charm = 250;
        mintableNFTCharacterStruct[characterID].imageURI = imageURI;
        mintableNFTCharacterStruct[characterID].name = name;
        mintableNFTCharacterStruct[characterID].description = description;
        totalMintableCharacters += 1;
    }

    function addCharacterTwo(
        uint256 health, // Health of the character
        string memory imageURI, // URI for the character's image
        string memory name, // Name of the character
        string memory description // Description of the character
    ) public {
        uint256 characterID = totalMintableCharacters;
        mintableNFTCharacterStruct[characterID].health = health;
        mintableNFTCharacterStruct[characterID].agility = 250;
        mintableNFTCharacterStruct[characterID].strength = 250;
        mintableNFTCharacterStruct[characterID].sneak = 250;
        mintableNFTCharacterStruct[characterID].charm = 500;
        mintableNFTCharacterStruct[characterID].imageURI = imageURI;
        mintableNFTCharacterStruct[characterID].name = name;
        mintableNFTCharacterStruct[characterID].description = description;
        totalMintableCharacters += 1;
    }

    function addCharacterThree(
        uint256 health, // Health of the character
        string memory imageURI, // URI for the character's image
        string memory name, // Name of the character
        string memory description // Description of the character
    ) public {
        uint256 characterID = totalMintableCharacters;
        mintableNFTCharacterStruct[characterID].health = health;
        mintableNFTCharacterStruct[characterID].agility = 250;
        mintableNFTCharacterStruct[characterID].strength = 500;
        intableNFTCharacterStruct[characterID].sneak = 250;
        mintableNFTCharacterStruct[characterID].charm = 250;
        mintableNFTCharacterStruct[characterID].imageURI = imageURI;
        mintableNFTCharacterStruct[characterID].name = name;
        mintableNFTCharacterStruct[characterID].description = description;
        totalMintableCharacters += 1;
    }

    function getNFTAttributes(
        uint256 NFTID
    )
        external
        view
        returns (
            uint256 agility,
            uint256 strength,
            uint256 charm,
            uint256 sneak,
            uint256 health
        )
    {
        return (
            characters[NFTID].agility,
            characters[NFTID].strength,
            characters[NFTID].charm,
            characters[NFTID].sneak,
            characters[NFTID].health
        );
    }

    function changeDescription(
        uint256 characterID,
        string memory description
    )
        public
        onlyOwner // Only owner can change the description
        returns (bool)
    {
        mintableNFTCharacterStruct[characterID].description = description;
        return true;
    }

    function changeImageURI(
        uint256 characterID,
        string memory imageURI
    )
        public
        onlyOwner // Only owner can change the image URI
        returns (bool)
    {
        mintableNFTCharacterStruct[characterID].imageURI = imageURI;
        return true;
    }

    function mintAnyCharacter(
        string memory name,
        uint256 characterID
    ) public payable returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet" // Check if there's enough LINK balance
        );
        require(
            characterID < totalMintableCharacters,
            "No Character With That ID" // Check if character with given ID exists
        );

        require(msg.value >= mintFee, "Send 0.002 Ether to mint New Character");

        bytes32 requestID = requestRandomness(keyHash, fee);
        requestToSender[requestID] = msg.sender; 
        NFTCharacterStruct[requestID].name = name; 
        NFTCharacterStruct[requestID].health = mintableNFTCharacterStruct[characterID].health;
            NFTCharacterStruct[requestID].agility = mintableNFTCharacterStruct[characterID].agility; 
        NFTCharacterStruct[requestID].strength = mintableNFTCharacterStruct[characterID].strength;
        NFTCharacterStruct[requestID].sneak = mintableNFTCharacterStruct[characterID].sneak;
        NFTCharacterStruct[requestID].characterID = characterID; 
    }
}
