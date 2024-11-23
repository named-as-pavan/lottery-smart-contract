// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// lib/chainlink-brownie-contracts/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol

// lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol

import {VRFConsumerBaseV2Plus} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**@title Raffle contract
 * @author Pavan Kumar
 * @notice Implements Chainlink VRFv2.5
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    // Errors
    error Raffle__SendMoreEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle__RaffleIsNotOpen();
    error Raffle_UpKeepNoNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    // Events

    // Type declarations

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // State variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;

    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private s_lastTimestamp;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // bool s_calculatingWinner = false;

    event RaffleEntered(address indexed player);

    event WinnerPicked(address indexed winner);

    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        // s_vrfCoordinator.requestRandomWords();
    }

    function enterRaffel() external payable {
        // require(msg.value >= i_entranceFee, SendMoreEnterRaffle());

        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleIsNotOpen();
        }
        s_players.push(payable(msg.sender));
        // emiting eveent to listen what is going on chain while working with frontend
        emit RaffleEntered(msg.sender);
    }

    // AWhen whould the winner should be ppicked

    /**
     * dev  This is the function that the Chainlink nodes willl call to see
     * if the lottery is ready to have winner picked.
     * The following should be true in order to upKeep to be true
     * 1.The time intercval has passed between raffle runs
     * 2. The lottery is open
     * The code has Eth
     * 4. Implicity your subscription has LINK
     * @param - Ignored
     * @return upkeepNeeded -true if it's time to restart the lottery
     * @return - Ignored
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimestamp) > i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if(!upKeepNeeded) {
            revert Raffle_UpKeepNoNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        if ((block.timestamp - s_lastTimestamp) < i_interval) {
            revert();
        }

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId,*/,
        uint256[] calldata randomWords
    ) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);

        s_lastTimestamp = block.timestamp;

        emit WinnerPicked(recentWinner);

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
        return s_players[indexOfPlayer];
    }

    function getLaastTimestamp() external view returns (uint256) {
        return s_lastTimestamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
