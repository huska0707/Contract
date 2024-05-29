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
        NFTCharacterStruct[requestID].health = mintableNFTCharacterStruct[
            characterID
        ].health;
        NFTCharacterStruct[requestID].agility = mintableNFTCharacterStruct[
            characterID
        ].agility;
        NFTCharacterStruct[requestID].strength = mintableNFTCharacterStruct[
            characterID
        ].strength;
        NFTCharacterStruct[requestID].sneak = mintableNFTCharacterStruct[
            characterID
        ].sneak;
        NFTCharacterStruct[requestID].characterID = characterID;
        return requestID;
    }

    function changeNFTAttributes(
        uint256 NFTID,
        uint256 health,
        uint256 agility,
        uint256 strength,
        uint256 sneak,
        uint256 charm
    ) external onlyGame {
        characters[NFTID].health = health;
        characters[NFTID].agility = agility;
        characters[NFTID].strength = strength;
        characters[NFTID].sneak = sneak;
        characters[NFTID].charm = charm;
        return true;
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee, // Check if contract has enough LINK to pay the VRF fee
            "Not enough LINK - fill contract with faucet" // Error message if there isn't enough LINK
        );

        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        uint256 newID = characters.length;
        uint256 agility = NFTCharacterStruct[requestId].agility +
            (randomness % 100);
        uint256 strength = NFTCharacterStruct[requestId].strength +
            ((randomness % 123456) % 100);
        uint256 sneak = NFTCharacterStruct[requestId].sneak +
            ((randomness % 654321) % 100);
        uint256 charm = NFTCharacterStruct[requestId].charm +
            ((randomness % 33576) % 100);
        uint256 born = block.timestamp;

        characters.push(
            NFTCharacter(
                NFTCharacterStruct[requestId].name,
                born,
                NFTCharacterStruct[requestId].health,
                agility,
                strength,
                sneak,
                NFTCharacterStruct[requestId].characterID
            )
        );
        _safeMint(requestToSender[requestId], newID);
    }

    function changeMintFee(uint256 newMintFee) public onlyOwner {
        mintFee = newMintFee;
        lastCheckIn = block.timestamp;
    }

    function changeGameAddress(address newGameAddress) public onlyOwner {
        gameAddress = newGameAddress;
    }

    function changeInheritance(address newInheritor) public onlyOwner {
        nextOwner = newInheritor;
        lastCheckIn = block.timestamp;
    }

    function ownerCheckIn() public onlyOwner {
        lastCheckIn = block.timestamp;
    }

    function changeCheckInTime(
        uint256 newCheckInTimeInterval
    ) public onlyOwner {
        checkInTimeInterval = newCheckInTimeInterval;
        lastCheckIn = block.timestamp;
    }

    function passDownInheritance() internal {
        transferOwnership(nextOwner);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        return (
            block.timestamp > (lastCheckIn + checkInTimeInterval),
            bytes("") // Return empty bytes as performData
        );
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override onlyKeeper {
        passDownInheritance();
    }

    function withdraw(uint256 amount) public onlyOwner returns (bool) {
        require(amount <= address(this).balance);
        payable(msg.sender).transfer(amount);
        return true;
    }

    function withdrawErc20(IERC20 token) public onlyOwner {
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))), // Transfer all tokens of the specified type to the owner
            "Transfer failed" // Error message if the transfer fails
        );
    }
}
