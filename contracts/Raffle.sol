//Raffle
//Enter the lottery (paying some amount)
//Pick a random winner(verifiably random)
//Winner to be selected every X minutes -> completely automated
//chainlink oracle -> Randomness,Automated Execution (Chainlink Keeper)

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/*Custom Error Function*/

error Raffle__NoEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/**
 * @title A sample Raffle Contract
 * @author Saurav Raj Paudel
 * @notice This contract is for creating an untamperable decentralized smart contract
 * @dev This implements Chainlink VRF v2 and Chainlink Automation(Previously known as Chainlink Keepers)
 */

/* Contract */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /*Types*/

    enum RaffleState {
        OPEN,
        CALCULATING
    } //uint256 0 = OPEN; 1 = calculating;

    /*State Variable*/

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_interval;

    //Lottery Variable:

    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;

    /*Event Section*/

    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Constructor*/

    constructor(
        address vrfCoordinatorV2, //contract
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        //VRFCoordinatorV2 is the contract that does verification stuff for us
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2); //This gives us the VRFCoordinatorInterface object(meaning access to all the function available in VRGCoordinator)
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    /* Function that enables the user to enter the lottery competetion*/

    /**
     * @dev This is the function that the user calls in order to enter the competetion
     * To enter the competetion the user needs to fulfill the following condition:
     * 1. The amount of eth send(msg.value) when calling this function must be greater that `i_entranceFee`.
     * 2.The raffle state must be open
     *
     * In addition the players address is push on to the address array `s_players`.
     * An even is emmitted containing the address of the caller of this function so that they can be recorded in the ethereum logs
     */

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NoEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the chainlink keeper nodes call
     * they look for the upkeepNeeded to turn true
     * The following should be true in order to return true:
     * 1. Our time interval should have passed
     * 2. The lottery should have at least 1 player, and have some ETH
     * 3. Our subscription is funded with LINK
     * 4. THe lottery should be an open state
     */

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData */
        )
    {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasBalance && hasPlayers);
    }

    /**
     *
     */

    function performUpkeep(
        bytes calldata /* perform data*/
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gasLane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length; //from where does randomWords get the random number????
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View/Pure/Getter Function */

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
