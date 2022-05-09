// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Function from NFTCollection to be called
interface INFTCollection {
    // TODO: Add things ?
}

contract Raffle {
    uint256 public cost = 0.01 ether;
    uint256 public ballotDate;

    // Some choice for storage of lottery player address
    // https://ethereum.stackexchange.com/questions/13167/are-there-well-solved-and-simple-storage-patterns-for-solidity
    // TODO: Review needed
    address[] lotteryPlayers;

    constructor (address nftContractAddress, uint256 date) {
        nftCollection = INFTCollection(nftContractAddress);
        ballotDate = date;
    }

    function isBallotTime() public view returns (bool) {
        return (now >= ballotDate);
    }

    // Pay to enter raffle
    function enterRaffle() public payable {
        require(!isBallotTime());
        require(msg.value == cost);
        // TODO: Protection from duplicate entry (or can duplicate?)
        // TODO: Check for pause as well?
        lotteryPlayers.push(msg.sender());
    }

    // Select winner
    // TODO: Must be call by owner only
    function drawRaffle() public {
        require(isBallotTime());
        // TODO: Integrate VRF here
        address winner = 0x1234; // hardcoded
        // TODO: Grant minter role to winner
    }
}