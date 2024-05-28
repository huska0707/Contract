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

contract BreakInGame is VRFConsumerBase, Ownable, KeeperCompatibleInterface {}
