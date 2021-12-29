// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./Board.sol";
import "./BoardToken.sol";

// The BigBoardz contract
// This contract must:
// DONE: create and sell initial board tokens 
// DONE: create boards for each board token it receives
// TODO: continuously or periodically get scores from chainlink node
// TODO: Announces completed games
// TODO: Announces upcoming games
// TODO: Announces starting games
// TODO: Announces end of season
// TODO: withdraw profit from factory hosted boards
// TODO: notify founderz about profits
// TODO: allow founderz to withdraw 
// TODO: allow anyone to create a franchise factory


contract BigBoardzFactory is Ownable, ChainlinkClient{
    using SafeMath for uint256;
    using Chainlink for Chainlink.Request;
    struct GameData {
        string status;
        string teams;
        uint[] score_away_by_period;
        uint[] score_home_by_period;
        uint score_away;
        uint score_home;
    }
    mapping (string => GameData) scores;
    mapping (address=> bool) founderz ;
    mapping (address => bool) approvedBoardz;
    mapping (address => string ) boardStatuses;
    Board public board;
    BoardToken public hostToken;
    uint256 private hTAvailableForLink;
    bytes32 factorydbEntryHash;
    bytes32 factorydbHash;
    event Bought(uint256 amount);
    event Sold(uint256 amount);



    constructor() public {
        // addresss polygon = 0xb0897686c545045afc77cf20ec7a532e3120e0f1
        // polygon chain id 137

         address mumbai = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        // mumbai chain id 80001
        
        setChainlinkToken(mumbai);
        // set founderz
        founderz(msg.sender) = true;
        // chainlink node
        // set chainlink node address
        oracle = abunchofstuff;
        jobId = "morestufftofill";
        fee = 0.1 * 10 ** 18; // set to score retreival fee

        // Deploy BoardToken contract
        hostToken = new BoardToken();
        founderzCut = 10000 * 10 ** decimals();
        hostToken.transfer(msg.sender, founderzCut);
        hTAvailableForLink = 400 * 10 ** decimals();

        // get orbit DB hash from chainlink node
        address(this).getDBHash();

    }

    //modifiers

    //hostOnly
    modifier onlyHost {
        require(hostToken.balanceOf(msg.sender) > 0);
        _;
    }

    //founder, host or chainlink keeper(MAYBE)
    modifier founderOrHostOnly {
        require(founderz(msg.sender) || hostToken.balanceOf(msg.sender) > 0);
    }



    function buyHostToken() payable public {

        uint256 hostTokensPerEth = 0.01111 * 10 ** decimals();
        uint256 amountTobuy = msg.value * hostTokensPerEth;

        uint256 factoryBalance = hostToken.balanceOf(address(this));

        require(amountTobuy > 0, "You need to send some ether");

        require(amountTobuy <= factoryBalance, "Not enough tokens in the reserve");

        hostToken.transfer(_msgSender(), amountTobuy);

        emit Bought(amountTobuy);

    }



    function buyHostTokenWithChainLink(uint256 amount) public {

        uint256 factoryBalance = hostToken.balanceOf(address(this));
        
        require(hTAvailableForLink <= factoryBalance, "Not enough host tokens in reserve");

        require(hTAvailableForLink > 0, "No more host tokens available for purchase with Link tokens");

        uint256 hostTokensPerLink = 1 * 10 ** decimals();
        
        uint256 amountTobuy = amount * hostTokensPerLink;

        require(amount > 0, "You must enter an amount of tokens to complete this transaction");

        require(amountTobuy <= factoryBalance, "Not enough host tokens in the reserve");

        require(LINK.transfer(address(this), amount, "Unable to transfer Link"));

        hostToken.transferFrom(address(this), msg.sender, amountTobuy);

        hTAvailableForLink.sub(amountTobuy);

    }



    function createBoard(uint gameId, uint256 boardFee, string boardHash) public onlyHost {

        //require message sender to have at least 1 hostToken
        uint256 creationFee = 1 * 10 ** decimals();
        
        require(hostToken.transferFrom(_msgSender(), address(this), creationFee));
        
        // deploy an instance of Board.sol 
        board = new Board(gameId, _msgSender(), boardFee);
        approvedBoardz(board) = true;
        boardStatuses(board) = 'OPEN';
    }

    function getDBHash(uint256 payment) public {
        // chainlink node call to get orbitDB hash for this factory
        uint256 specId = 1;
        Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfillDBHash.selector);
        req.addUint("times", 10000);
        requestOracleData(req, payment);
    }

    function fulfillDBHash(bytes32 dbHash) public recordChainlinkFulfillment(requestId){
        factorydbHash = dbHash;
    }

    function getGameStatuses(uint256 payment) external {
    uint256 specId = 2;
    Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfillGameStatuses.selector);
    req.addUint("times", 10000);
    requestOracleData(req, payment);

    }

    // 1 event
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0
        ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 2 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 3 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 4 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 5 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3,
        bytes32 eventId4,
        bytes32 status4
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 6 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3,
        bytes32 eventId4,
        bytes32 status4,
        bytes32 eventId5,
        bytes32 status5
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 7 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3,
        bytes32 eventId4,
        bytes32 status4,
        bytes32 eventId5,
        bytes32 status5,
        bytes32 eventId6,
        bytes32 status6
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 8 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3,
        bytes32 eventId4,
        bytes32 status4,
        bytes32 eventId5,
        bytes32 status5,
        bytes32 eventId6,
        bytes32 status6,
        bytes32 eventId7,
        bytes32 status7
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 9 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3,
        bytes32 eventId4,
        bytes32 status4,
        bytes32 eventId5,
        bytes32 status5,
        bytes32 eventId6,
        bytes32 status6,
        bytes32 eventId7,
        bytes32 status7,
        bytes32 eventId8,
        bytes32 status8
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 10 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3,
        bytes32 eventId4,
        bytes32 status4,
        bytes32 eventId5,
        bytes32 status5,
        bytes32 eventId6,
        bytes32 status6,
        bytes32 eventId7,
        bytes32 status7,
        bytes32 eventId8,
        bytes32 status8,
        bytes32 eventId9,
        bytes32 status9,
        bytes32 eventId10,
        bytes32 status10
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 11 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3,
        bytes32 eventId4,
        bytes32 status4,
        bytes32 eventId5,
        bytes32 status5,
        bytes32 eventId6,
        bytes32 status6,
        bytes32 eventId7,
        bytes32 status7,
        bytes32 eventId8,
        bytes32 status8,
        bytes32 eventId9,
        bytes32 status9,
        bytes32 eventId10,
        bytes32 status10
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }

    // 12 events
    function fulfillGameStatuses(
        bytes32 eventId0,
        bytes32 status0,
        bytes32 eventId1,
        bytes32 status1,
        bytes32 eventId2,
        bytes32 status2,
        bytes32 eventId3,
        bytes32 status3,
        bytes32 eventId4,
        bytes32 status4,
        bytes32 eventId5,
        bytes32 status5,
        bytes32 eventId6,
        bytes32 status6,
        bytes32 eventId7,
        bytes32 status7,
        bytes32 eventId8,
        bytes32 status8,
        bytes32 eventId9,
        bytes32 status9,
        bytes32 eventId10,
        bytes32 status10,
        bytes32 eventId11,
        bytes32 status11
    ) 
        public 
        recordChainlinkFulfillment(requestId)
    {
        // emit status event for each data pair

    }


    /**
     * Withdraw LINK from this contract
     * 
     * DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES.
     */
    /* function withdrawLink() external {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    } */
}