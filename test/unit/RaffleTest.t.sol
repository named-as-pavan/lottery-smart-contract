// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src//StdInvariant.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";

contract RaffleTest is StdInvariant, Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    address public PLAYER = makeAddr("player");

    uint256 public constant STARTING_PLAYER_BAL = 20 ether;

    event RaffleEntered(address indexed player);

    event WinnerPicked(address indexed winner);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        vm.deal(PLAYER, STARTING_PLAYER_BAL);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenDontPayEnoughMoney() public {
        //Arrange
        vm.prank(PLAYER);
        // Act
        // Asset
        vm.expectRevert(Raffle.Raffle__SendMoreEnterRaffle.selector);
        raffle.enterRaffel();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffel{value: entranceFee}();
        // Asset
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // Assert
        raffle.enterRaffel{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffel{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Act
        // Assert

        vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffel{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////*
//                         CHECKUPKEEP
    //////////////////////////////////////////////////////////////*/

    function testCheckUpKeyReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act

        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeyReturnsFalseIfReffleIsntopen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffel{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upKeepNeeded);
    }

    // function testCheckUpKeyReturnsFalseIfEnoughTimeHasPassed() public {
    //     // Arrange
    //     vm.prank(PLAYER);
    //     raffle.enterRaffel{value: entranceFee}();
    //     vm.warp(block.timestamp + interval + 1);
    //     vm.roll(block.number + 1);
    //     raffle.performUpkeep("");
    // Act
    // Assert

    /*//////////////////////////////////////////////////////////////*
                            //  PERFORMUPKEEP                       //
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        public
        raffleEntered
    {
        // Arrange

        // Used modifiers and checked in function call only so commented

        // vm.prank(PLAYER);
        // raffle.enterRaffel{value: entranceFee}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);
        // Act

        // Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Act
        vm.prank(PLAYER);
        raffle.enterRaffel{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = numPlayers + 1;

        // Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpKeepNoNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffel{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if(block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitRequestID()
        public
        raffleEntered skipFork
    {
        // Arrange

        // Used modifiers and checked in function call only so commented

        // vm.prank(PLAYER);
        // raffle.enterRaffel{value: entranceFee}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);
        // Act
        // To log some emited events in block-chain solidity
        vm.recordLogs();

        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /*//////////////////////////////////////////////////////////////*
                        //    FULLFILLRANDOMWORDS                  //
    //////////////////////////////////////////////////////////////*/

    // randomRequestId is just a random parameter name declared to run fuzz tests //

    function testFullFillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntered skipFork{
        // Arrange
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
        // Act
        // Assert
    }

    function testfulFillrandomWordsPicksWinnerResetsAndSendMoney()
        public
        raffleEntered
        skipFork
    {
        // Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for(uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address newPlayer = address(uint160(i));
            // just setting prank for all users using hoax cheatcode
            hoax(newPlayer,1 ether);
            raffle.enterRaffel{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLaastTimestamp();
        uint256 winnerStartingBalance = expectedWinner.balance;


        // Act
        vm.recordLogs();

        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId), address(raffle)
        );
        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        uint256 winnerBalance = recentWinner.balance;

        uint256 endingTimeStamp = raffle.getLaastTimestamp();
        // +1 because to include winner's entrancefee also
        uint256 prize = entranceFee * (additionalEntrants + 1);


        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}

// Arrange
// Act
// Assert
