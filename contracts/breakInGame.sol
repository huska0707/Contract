// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface INFTMinter {
    function getNFTAttributes(
        uint256 NFTID
    )
        external
        returns (
            uint256 agility,
            uint256 strength,
            uint256 charm,
            uint256 sneak,
            uint256 health
        );

    function changeNFTAttributes(
        uint256 NFTID,
        uint256 health,
        uint256 agility,
        uint256 strength,
        uint256 sneak,
        uint256 charm
    ) external returns (bool);
}

contract BreakInGame is VRFConsumerBase, Ownable, KeeperCompatibleInterface {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    address keeperRegistryAddress;

    modifier onlyKeeper() {
        require(msg.sender == keeperRegistryAddress);
        _;
    }

    uint256 hospitalBill = 1000 * 10 ** 18;
    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000; // Default to six months
    address public nextOwner;

    INFTMinter IBreakInNFTMinter;
    IERC721 breakInNFT;
    IERC20 socialLegoToken;

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _keeperRegistryAddress,
        address _breakInNFT,
        address _socialLegoToken
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyHash;
        fee = _fee;
        keeperRegistryAddress = _keeperRegistryAddress;
        IBreakInNFTMinter = INFTMinter(_breakInNFT);
        breakInNFT = IERC721(_breakInNFT);
        socialLegoToken = IERC20(_socialLegoToken);
    }

    struct scenarios {
        string name;
        uint256 riskBaseDifficulty;
        uint256 payoutAmountBase;
    }

    struct NFTCharacter {
        uint256 born;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        uint256 characterID;
    }

    struct depostedCharacter {
        uint256 NFTID;
        bool isDeposited;
        bool arrested;
        uint256 freetoPlayAgain;
        bool playingPVP;
        uint256 canStopPlayingPVP;
        uint256 lootingTimeout;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
    }

    struct gamePlay {
        address player;
        uint256 scenario;
        uint256 breakInStyle;
        uint256 difficultyLevel;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
    }

    struct jailBreak {
        address player;
        uint256 breakInStyle;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        address targetPlayer;
    }

    struct PvP {
        address player;
        uint256 breakInStyle;
        uint256 difficultyLevel;
        uint256 health;
        uint256 agility;
    }
}
