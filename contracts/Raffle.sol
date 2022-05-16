// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./NFTCollection.sol";

contract Raffle is NFTCollection, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 s_keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;

    uint256 public cost = 0.001 ether;
    uint256 public minNumPlayers = 2;
    uint256 public ballotTime;

    // Some choice for storage of lottery player address
    // https://ethereum.stackexchange.com/questions/13167/are-there-well-solved-and-simple-storage-patterns-for-solidity
    // TODO: Review needed
    address[] public lotteryPlayers;

    event WinnerSelected(address winner);

    constructor(uint64 subscriptionId, 
                address vrfCoordinator,
                bytes32 keyHash,
                uint256 date)
                VRFConsumerBaseV2(vrfCoordinator) 
                NFTCollection()
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        ballotTime = date;
    }

    function isBallotTime() public view returns (bool) {
        return (block.timestamp >= ballotTime);
    }

    // Pay to enter raffle
    function enterRaffle() public payable {
        require(!isBallotTime());
        require(!paused());
        require(msg.value == cost);
        // TODO: Protection from duplicate entry (or can duplicate?)
        lotteryPlayers.push(msg.sender);
    }

    // Select winner
    function drawRaffle() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isBallotTime());
        require(lotteryPlayers.length >= minNumPlayers);
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        // TODO: Match request ID
        s_randomWords = randomWords;
        // Modulus to ensure random within range 0..N-1 where N is total number of player
        address winner = lotteryPlayers[s_randomWords[0] % lotteryPlayers.length];
        _grantRole(MINTER_ROLE, winner);
        emit WinnerSelected(winner);
        // What's next? Only allow 1 specific tokenURI ?
    }

    function setBallotTime(uint256 date) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ballotTime = date;
    }

    function setCost(uint256 raffleCost) public onlyRole(DEFAULT_ADMIN_ROLE) {
        cost = raffleCost;
    }

    function setMinNumPlayers(uint256 num) public onlyRole(DEFAULT_ADMIN_ROLE) {
        minNumPlayers = num;
    }

    function getTotalPlayers() public view returns (uint256) {
        return lotteryPlayers.length;
    }
}
