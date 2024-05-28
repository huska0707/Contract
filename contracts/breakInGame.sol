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

        if (currentGamePlays[requestId].breakInStyle == 2) {
            uint256 strengthInExperienceRequired = ((randomness % 786435) %
                750) +
                currentGamePlays[requestId].difficultyLevel +
                gameScenarios[currentGamePlays[requestId].scenario]
                    .riskBaseDifficulty;
            if (
                currentGamePlays[requestId].strength >
                strengthInExperienceRequired
            ) {
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
                    ].strength += 1;
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

    function vrfJailBreak(uint256 randomness, bytes32 requestId) internal {
        // only when randomness is returned can this function be called.
        if ((randomness % 1000) == 1) {
            // 5x higher chance of dying because its a jail
            // 1 in 1000 chance character dies
            NFTCharacterDepositLedger[currentJailBreaks[requestId].player]
                .isDeposited = false; //
            emit gameCode(requestId, currentJailBreaks[requestId].player, 0);
            return;
        }

        if (((randomness % 143456) % 10) == 1) {
            //2x higher chance of getting injured
            // 1 in 100 chance character is injured
            uint256 healthDecrease = ((randomness % 123456) % 99); // player can lose up to 99 health every 1 in 100
            if (
                (100 - currentJailBreaks[requestId].health + healthDecrease) >
                100
            ) {
                // players don't have to heal if they get injured before but if they get injured again and its greater than 100, they die
                NFTCharacterDepositLedger[msg.sender].isDeposited = false; //
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].player,
                    0
                );
                return;
            }
            NFTCharacterDepositLedger[currentJailBreaks[requestId].player]
                .health -= healthDecrease;
            emit gameCode(requestId, currentJailBreaks[requestId].player, 1);
            return;
        }
        if (((randomness % 23015) % 5) == 1) {
            // really high chance of getting spotted
            // 1 in 5 chance character is almost getting arrested
            uint256 agilityRequiredtoEscape = ((randomness % 54321) % 1000); // player still has chance to escape
            if (
                currentJailBreaks[requestId].agility > agilityRequiredtoEscape
            ) {
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentJailBreaks[requestId].player
                    ].agility += 1;
                }
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].player,
                    3
                );
                return; // escaped but no money given
            } else {
                NFTCharacterDepositLedger[msg.sender].arrested = true;
                NFTCharacterDepositLedger[msg.sender].freetoPlayAgain =
                    block.timestamp +
                    259200; //player arrested for 3 days.
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].player,
                    2
                );
                return; //  playerArrested
            }
        }
        if (currentJailBreaks[requestId].breakInStyle == 0) {
            //player is sneaking in
            uint256 sneakInExperienceRequired = ((randomness % 235674) % 1000); // difficulty will be somewhere between 0 to 10000
            if (
                currentJailBreaks[requestId].sneak > sneakInExperienceRequired
            ) {
                NFTCharacterDepositLedger[
                    currentJailBreaks[requestId].targetPlayer
                ].arrested = false;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentJailBreaks[requestId].player
                    ].sneak += 1;
                }
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].targetPlayer,
                    5
                );
                return;
            }
            emit gameCode(requestId, currentJailBreaks[requestId].player, 4);
            return;
        }
        if (currentJailBreaks[requestId].breakInStyle == 1) {
            // player is breaking in with charm
            uint256 charmInExperienceRequired = ((randomness % 453678) % 1000);
            if (
                currentJailBreaks[requestId].charm > charmInExperienceRequired
            ) {
                NFTCharacterDepositLedger[
                    currentJailBreaks[requestId].targetPlayer
                ].arrested = false;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentJailBreaks[requestId].player
                    ].charm += 1;
                }
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].targetPlayer,
                    5
                );
                return;
            }
            emit gameCode(requestId, currentJailBreaks[requestId].player, 4);
            return;
        }
        if (currentJailBreaks[requestId].breakInStyle == 2) {
            // player is breaking in with strength
            uint256 strengthInExperienceRequired = ((randomness % 786435) %
                1000);
            if (
                currentJailBreaks[requestId].strength >
                strengthInExperienceRequired
            ) {
                NFTCharacterDepositLedger[
                    currentJailBreaks[requestId].targetPlayer
                ].arrested = false;
                if (((randomness % 2214) % 4) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentJailBreaks[requestId].player
                    ].strength += 1;
                }
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].targetPlayer,
                    5
                );
                return;
            }
            emit gameCode(requestId, currentJailBreaks[requestId].player, 4);
            return;
        }
    }
    function vrfPlayPVP(uint256 randomness, bytes32 requestId) internal {
        // only when randomness is returned can this function be called.
        if ((randomness % 100) == 1) {
            //  really high chance of getting killed
            // 1 in 100 chance character dies
            NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                .isDeposited = false; //
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 0);
            return;
        }

        if (((randomness % 143456) % 11) == 3) {
            //really high chance of getting injured
            // 1 in 11 chance character is injured
            uint256 healthDecrease = ((randomness % 123456) % 99); // player can lose up to 99 health every 1 in 100
            if (
                (100 - currentPVPGamePlays[requestId].health + healthDecrease) >
                100
            ) {
                // players don't have to heal if they get injured before but if they get injured again and its greater than 100, they die
                NFTCharacterDepositLedger[msg.sender].isDeposited = false; //
                emit gameCode(
                    requestId,
                    currentPVPGamePlays[requestId].player,
                    0
                );
                return;
            }
            NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                .health -= healthDecrease;
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 1);
            return;
        }
        // no chance of getting arrested since you are a robbing another player
        // There is nothing stopping players with 800 sneak targeting players with 300 sneak.
        // It is assumed that the 800 sneak character will be more vulnerbale to strength attacks.
        // Players have to decide if they want to play more defensivly by equally levelling up each trait
        // or focus on one specfic trait which allows them to attack better but have worse defense.
        // Oh and please hire me.
        if (currentPVPGamePlays[requestId].breakInStyle == 0) {
            //player is sneaking in
            uint256 sneakInExperienceRequired = ((randomness % 235674) % 1000) +
                currentPVPGamePlays[requestId].targetPlayerSneak; // difficulty will be somewhere between 0 to 10000 plus the difficulty level which will be about 100 to 950
            if (
                currentPVPGamePlays[requestId].sneak > sneakInExperienceRequired
            ) {
                uint256 totalWon = jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] / 20; // player can only lose 5% max each day
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentPVPGamePlays[requestId].player
                    ].sneak += 1;
                }
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] -= totalWon;
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].player
                ] += totalWon;
                NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                    .lootingTimeout = block.timestamp + 86400; // players can only loot once a day
                NFTCharacterDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ].lootingTimeout = block.timestamp + 86400; // players can only get looted once a day
                emit gameCode(
                    requestId,
                    currentPVPGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 4);
            return;
        }
        if (currentPVPGamePlays[requestId].breakInStyle == 1) {
            // player is breaking in with charm
            uint256 charmInExperienceRequired = ((randomness % 453678) % 1000) +
                currentPVPGamePlays[requestId].targetPlayerCharm;
            if (
                currentPVPGamePlays[requestId].charm > charmInExperienceRequired
            ) {
                uint256 totalWon = jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] / 20;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentPVPGamePlays[requestId].player
                    ].charm += 1;
                }
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].player
                ] += totalWon;
                NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                    .lootingTimeout = block.timestamp + 86400; // players can only loot once a day
                NFTCharacterDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ].lootingTimeout = block.timestamp + 86400; // players can only get looted once a day
                emit gameCode(
                    requestId,
                    currentPVPGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 4);
            return;
        }
        if (currentPVPGamePlays[requestId].breakInStyle == 2) {
            // player is breaking in with strength
            uint256 strengthInExperienceRequired = ((randomness % 786435) %
                1000) + currentPVPGamePlays[requestId].targetPlayerStrength; // strength is used for daylight robbery
            if (
                currentPVPGamePlays[requestId].strength >
                strengthInExperienceRequired
            ) {
                uint256 totalWon = jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] / 20; // player can only lose 5% max each day
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentPVPGamePlays[requestId].player
                    ].strength += 1;
                }
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] -= totalWon;
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].player
                ] += totalWon;
                NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                    .lootingTimeout = block.timestamp + 86400; // players can only loot once a day
                NFTCharacterDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ].lootingTimeout = block.timestamp + 86400; // players can only get looted once a day
                emit gameCode(
                    requestId,
                    currentPVPGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 4);
            return;
        }
    }

    function getRandomNumber() internal returns (bytes32 requestId) {}
}
