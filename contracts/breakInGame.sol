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
    }
}
