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
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        address targetPlayer;
        uint256 targetPlayerHealth;
        uint256 targetPlayerAgility;
        uint256 targetPlayerStrength;
        uint256 targetPlayerSneak;
        uint256 targetPlayerCharm;
    }

    struct gameModes {
        uint256 gameMode; // 0 if robbing, 1 if jailBreak, 2 if PvP
    }

    event gameCode(bytes32 requestID, address player, uint256 code);
    uint256 differentGameScenarios;

    mapping(uint256 => scenarios) public gameScenarios;
    mapping(bytes32 => PvP) currentPVPGamePlays;
    mapping(bytes32 => gamePlay) currentGamePlays;
    mapping(bytes32 => gameModes) currentGameMode;
    mapping(bytes32 => jailBreak) currentJailBreaks;
    mapping(address => depostedCharacter) public NFTCharacterDepositLedger;
    mapping(address => uint256) public jewelDepositLedger;

    function changeHospitalBill(uint256 newHospitalBill) public onlyOwner {
        hospitalBill = newHospitalBill;
        lastCheckIn = block.timestamp;
    }

    function addScenario(
        string memory name,
        uint16 riskBaseDifficulty,
        uint256 payoutAmountBase
    ) public onlyOwner {
        uint256 gameScenarioID = differentGameScenarios;
        gameScenarios[gameScenarioID].name = name;
        gameScenarios[gameScenarioID].riskBaseDifficulty = riskBaseDifficulty;
        gameScenarios[gameScenarioID].payoutAmountBase = payoutAmountBase;
        differentGameScenarios += 1;
    }

    function modifyScenario(
        uint256 scenarioNumber,
        string memory name,
        uint16 riskBaseDifficulty,
        uint16 payoutAmountBase
    ) public onlyOwner {
        gameScenarios[scenarioNumber].riskBaseDifficulty = riskBaseDifficulty; // Scenarios can be removed by effectively raising the riskbase difficult level so high no one would bother playing it and making payoutAmountBase 0
        gameScenarios[scenarioNumber].payoutAmountBase = payoutAmountBase;
        gameScenarios[scenarioNumber].name = name;
    }

    function depositNFT(uint256 NFTID) public {
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited != true,
            "Character Already Deposited"
        );
        breakInNFT.transferFrom(msg.sender, address(this), NFTID);
        NFTCharacterDepositLedger[msg.sender].NFTID = NFTID;
        NFTCharacterDepositLedger[msg.sender].isDeposited = true;
        (
            NFTCharacterDepositLedger[msg.sender].agility,
            NFTCharacterDepositLedger[msg.sender].strength,
            NFTCharacterDepositLedger[msg.sender].charm,
            NFTCharacterDepositLedger[msg.sender].sneak,
            NFTCharacterDepositLedger[msg.sender].health
        ) = IBreakInNFTMinter.getNFTAttributes(
            NFTCharacterDepositLedger[msg.sender].NFTID
        );
    }

    function withdrawNFT() public {
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "No Character Deposited"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].arrested == false,
            "Character in Prison"
        );

        IBreakInNFTMinter.changeNFTAttributes(
            NFTCharacterDepositLedger[msg.sender].NFTID,
            NFTCharacterDepositLedger[msg.sender].health,
            NFTCharacterDepositLedger[msg.sender].agility,
            NFTCharacterDepositLedger[msg.sender].strength,
            NFTCharacterDepositLedger[msg.sender].sneak,
            NFTCharacterDepositLedger[msg.sender].charm
        );

        breakInNFT.transferFrom(
            address(this),
            msg.sender,
            NFTCharacterDepositLedger[msg.sender].NFTID
        );

        NFTCharacterDepositLedger[msg.sender].isDeposited = false;
    }

    function depositJewels(uint256 amountToDeposit) public {
        require(
            NFTCharacterDepositLedger[msg.sender].arrested == false,
            "Character in Prison"
        );
        socialLegoToken.transferFrom(
            msg.sender,
            address(this),
            amountToDeposit
        );
        jewelDepositLedger[msg.sender] += amountToDeposit;
    }

    function withdrawJewels(uint256 amountToWithdraw) public {
        require(
            jewelDepositLedger[msg.sender] >= amountToWithdraw,
            "Trying to withdraw too much money"
        );

        socialLegoToken.transfer(msg.sender, amountToWithdraw);
        jewelDepositLedger[msg.sender] -= amountToWithdraw;
    }

    function startPlayPVP() public {
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "Character Not deposited"
        );

        NFTCharacterDepositLedger[msg.sender].playingPVP = true;
        NFTCharacterDepositLedger[msg.sender].canStopPlayingPVP =
            block.timestamp +
            604800;
    }

    function stopPlayPVP() public {
        require(
            block.timestamp >=
                NFTCharacterDepositLedger[msg.sender].canStopPlayingPVP,
            "You must wait 7 days since you started playing"
        );
        NFTCharacterDepositLedger[msg.sender].playingPVP = false;
    }

    function hospitalVisit() public {
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "Character Not Deposited"
        );
        require(NFTCharacterDepositLedger[msg.sender].health < 100);
        require(jewelDepositLedger[msg.sender] >= (hospitalBill));
        jewelDepositLedger[msg.sender] -= hospitalBill;
        NFTCharacterDepositLedger[msg.sender].health = 100;
    }

    function playGame(
        uint256 difficultyLevel,
        uint256 breakInStyle,
        uint256 scenario
    ) public returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "No Character Deposited"
        );

        require(
            NFTCharacterDepositLedger[msg.sender].arrested == false,
            "Character in Prison"
        );

        require(scenario < differentGameScenarios, "No Game Scenario");
        bytes32 requestID = requestRandomness(keyHash, fee);
        currentGameMode[requestID].gameMode = 0;

        currentGamePlays[requestID].player = msg.sender;
        currentGamePlays[requestID].breakInStyle = breakInStyle;
        currentGamePlays[requestID].difficultyLevel = difficultyLevel;
        currentGamePlays[requestID].scenario = scenario;
        currentGamePlays[requestID].agility = NFTCharacterDepositLedger[
            msg.sender
        ].agility;
        currentGamePlays[requestID].strength = NFTCharacterDepositLedger[
            msg.sender
        ].strength;
        currentGamePlays[requestID].charm = NFTCharacterDepositLedger[
            msg.sender
        ].charm;
        currentGamePlays[requestID].sneak = NFTCharacterDepositLedger[
            msg.sender
        ].sneak;
        currentGamePlays[requestID].health = NFTCharacterDepositLedger[
            msg.sender
        ].health;

        return requestID;
    }

    function playBreakOut(
        uint256 breakInStyle,
        address targetPlayer
    ) public returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );

        require(
            NFTCharacterDepositLedger[targetPlayer].isDeposited == true,
            "No Target Character Deposited"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "You have no Character Deposited"
        );

        require(
            NFTCharacterDepositLedger[targetPlayer].arrested == true,
            "Character is not in Prison"
        );

        require(targetPlayer != msg.sender, "You cannot free yourself");
        bytes32 requestID = requestRandomness(keyHash, fee);
        currentGameMode[requestID].gameMode = 1;

        currentJailBreaks[requestID].player = msg.sender;
        currentJailBreaks[requestID].breakInStyle = breakInStyle;
        currentJailBreaks[requestID].targetPlayer = targetPlayer;
        currentJailBreaks[requestID].agility = NFTCharacterDepositLedger[
            msg.sender
        ].agility;
        currentJailBreaks[requestID].strength = NFTCharacterDepositLedger[
            msg.sender
        ].strength;
        currentJailBreaks[requestID].charm = NFTCharacterDepositLedger[
            msg.sender
        ].charm;
        currentJailBreaks[requestID].sneak = NFTCharacterDepositLedger[
            msg.sender
        ].sneak;
        currentJailBreaks[requestID].health = NFTCharacterDepositLedger[
            msg.sender
        ].health;

        return requestID;
    }

    function playPVP(
        uint256 breakInStyle,
        address targetPlayer
    ) public returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(
            NFTCharacterDepositLedger[targetPlayer].isDeposited == true,
            "No Target Character Deposited"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "You have no Character Deposited"
        );
        require(targetPlayer != msg.sender, "You cannot rob from yourself");
        require(
            NFTCharacterDepositLedger[msg.sender].lootingTimeout <
                block.timestamp
        );

        require(
            NFTCharacterDepositLedger[targetPlayer].lootingTimeout <
                block.timestamp
        );
        require(jewelDepositLedger[targetPlayer] > (1 * 10 ** 18));
        require(
            jewelDepositLedger[msg.sender] >
                (jewelDepositLedger[targetPlayer] / 2)
        );
        bytes32 requestID = requestRandomness(keyHash, fee);
        currentGameMode[requestID].gameMode = 2;

        currentPVPGamePlays[requestID].player = msg.sender;
        currentPVPGamePlays[requestID].breakInStyle = breakInStyle;
        currentPVPGamePlays[requestID].targetPlayer = targetPlayer;
        currentPVPGamePlays[requestID].agility = NFTCharacterDepositLedger[
            msg.sender
        ].agility;
        currentPVPGamePlays[requestID].strength = NFTCharacterDepositLedger[
            msg.sender
        ].strength;
        currentPVPGamePlays[requestID].charm = NFTCharacterDepositLedger[
            msg.sender
        ].charm;
        currentPVPGamePlays[requestID].sneak = NFTCharacterDepositLedger[
            msg.sender
        ].sneak;
        currentPVPGamePlays[requestID].health = NFTCharacterDepositLedger[
            msg.sender
        ].health;
        currentPVPGamePlays[requestID]
            .targetPlayerAgility = NFTCharacterDepositLedger[targetPlayer]
            .agility;
        currentPVPGamePlays[requestID]
            .targetPlayerStrength = NFTCharacterDepositLedger[targetPlayer]
            .strength;
        currentPVPGamePlays[requestID]
            .targetPlayerCharm = NFTCharacterDepositLedger[targetPlayer].charm;
        currentPVPGamePlays[requestID]
            .targetPlayerSneak = NFTCharacterDepositLedger[targetPlayer].sneak;
        currentPVPGamePlays[requestID]
            .targetPlayerHealth = NFTCharacterDepositLedger[targetPlayer]
            .health;

        return requestID;
    }

    function vrfPlayGame(uint256 randomness, bytes32 requestId) internal {
        if ((randomness % 2000) == 1) {
            // 1 in 2000 chance character dies
            NFTCharacterDepositLedger[currentGamePlays[requestId].player]
                .isDeposited = false;
            emit gameCode(requestId, currentGamePlays[requestId].player, 0);
            return;
        }
        if (((randomness % 143456) % 20) == 1) {
            // 1 in 20 chance character is injured
            uint256 healthDecrease = ((randomness % 123456) % 99);

            if (
                (100 - currentGamePlays[requestId].health + healthDecrease) >
                100
            ) {
                // players don't have to heal if they get injured before but if they get injured again and its greater than 100, they die
                NFTCharacterDepositLedger[currentGamePlays[requestId].player]
                    .isDeposited = false;
                emit gameCode(requestId, currentGamePlays[requestId].player, 0);
                return;
            }

            NFTCharacterDepositLedger[currentGamePlays[requestId].player]
                .health -= healthDecrease;
            emit gameCode(requestId, currentGamePlays[requestId].player, 1);
            return;
        }

        if (currentGamePlays[requestId].breakInStyle == 0) {
            uint256 sneakInExperienceRequired = ((randomness % 235674) % 750) +
                currentGamePlays[requestId].difficultyLevel +
                gameScenarios[currentGamePlays[requestId].scenario]
                    .riskBaseDifficulty;
            if (currentGamePlays[requestId].sneak > sneakInExperienceRequired) {
                uint256 totalWon = currentGamePlays[requestId].difficultyLevel *
                    gameScenarios[currentGamePlays[requestId].scenario]
                        .payoutAmountBase;
                jewelDepositLedger[
                    currentGamePlays[requestId].player
                ] += totalWon;
                // Player gains XP if successful
                if (((randomness % 2214) % 2) == 1) {
                    NFTCharacterDepositLedger[
                        currentGamePlays[requestId].player
                    ].sneak += 1;
                }
                emit gameCode(
                    requestId,
                    currentGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentGamePlays[requestId].player, 4);
            return;
        }

        if (currentGamePlays[requestId].breakInStyle == 1) {
            uint256 charmInExperienceRequired = ((randomness % 453678) % 750) +
                currentGamePlays[requestId].difficultyLevel +
                gameScenarios[currentGamePlays[requestId].scenario]
                    .riskBaseDifficulty;
            if (currentGamePlays[requestId].charm > charmInExperienceRequired) {
                uint256 totalWon = currentGamePlays[requestId].difficultyLevel *
                    gameScenarios[currentGamePlays[requestId].scenario]
                        .payoutAmountBase;
                jewelDepositLedger[
                    currentGamePlays[requestId].player
                ] += totalWon;
                // Player gains XP if successful
                if (((randomness % 2214) % 2) == 1) {
                    NFTCharacterDepositLedger[
                        currentGamePlays[requestId].player
                    ].charm += 1;
                }
                emit gameCode(
                    requestId,
                    currentGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentGamePlays[requestId].player, 4);
            return;
        }
    }
}
