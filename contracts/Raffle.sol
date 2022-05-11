// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./NFTCollection.sol";

contract Raffle is NFTCollection, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    uint256 public cost = 0.01 ether;
    uint256 public minNumPlayers = 2;
    uint256 public ballotDate;

    // Some choice for storage of lottery player address
    // https://ethereum.stackexchange.com/questions/13167/are-there-well-solved-and-simple-storage-patterns-for-solidity
    // TODO: Review needed
    address[] public lotteryPlayers;

    constructor(uint64 subscriptionId, uint256 date)
        VRFConsumerBaseV2(vrfCoordinator) NFTCollection()
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        ballotDate = date;
    }

    function isBallotTime() public view returns (bool) {
        return (block.timestamp >= ballotDate);
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
        uint256 totalPlayers = lotteryPlayers.length;
        require(totalPlayers >= minNumPlayers);
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        // Modulus to ensure random within range 0..N-1 where N is total number of player
        address winner = lotteryPlayers[s_randomWords[0] % totalPlayers];
        _grantRole(MINTER_ROLE, winner);
        // What's next? Only allow 1 specific tokenURI ?
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }
}
