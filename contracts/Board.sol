// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

//
// The Board contract
//
contract Board is Ownable, AccessControl {

    struct Square {
        address payable purchaser;
        string squareHash;
    }

    bytes32 internal keyHash;
    // bytes32 internal boardDBEntryHash;
    bytes32 internal boardDBHash;
    uint256 internal linkFee;
    string gameId;
    string dbAddress;
    address payable host;
    address payable admin;
    uint internal boardFee;
    address internal feeToken;
    uint internal forwardPrize;
    uint internal backwardPrize;
    uint availableSquarezCount;
    enum GameState{STARTED, OVER}
    enum BoardStatus{OPEN, SOLDOUT, CANCELED, CLOSED}
    GameState game;
    BoardStatus internal boardStatus;
    Square[100] internal squareBuyerz;
    
    mapping(address => uint) private winners;
    uint256 private winnerCount;
    // mapping(address => uint) backwardWinners;
    mapping(address => bool) private prizeCollectedByWinner;
    uint256 private prizesCollectedCount;
    bool private hostProfitsCollected;

    event PrizeCollected(address winner, uint totalAmount);
    event SquarePurchased(address purchaser);

    constructor(string _gameId, address _host, uint _boardFee, address _feeToken) 
      public {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        linkFee = 0.0001 * 10 ** 18; // 0.0001 LINK
        // set gameId
        gameId = _gameId;
        // set host
        host = _host;
        // set admin
        admin = msg.sender;
        // set boardFee;
        boardFee = _boardFee;

        //board fee token
        //  dai: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        // usdc: 0x2791bca1f2de4661ed88a30c99a7a9449aa84174
        // usdt: 0xc2132d05d31c914a87c6611c10748aeb04b58e8f

        forwardPrize = boardFee * 15;
        backwardPrize = forwardPrize / 2;
        // availableSquarezCount = 100;
        boardStatus = BoardStatus.PENDING;
        prizesCollectedCount = 0;
    }

    // modifiers

    //adminOnly
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    //hostOnly
    modifier onlyHost {
        require(msg.sender == host);
        _;
    }

    //adminOrHostOnly
    modifier adminOrHostOnly {
        require(msg.sender == admin || msg.sender == host);
        _;
    }

    //winnerOnly
    modifier winnerOnly {
        require(winners(msg.sender) > 0 /* || backwardWinners(msg.sender) > 0 */);
        _;
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

    // purchaseSquare method:
    receive() external payable {
        require(msg.value == boardFee, "Please pay full board fee using required token.");
    }

    function buySquare(string squareHash) external {
        require(IERC20(feeToken).transferFrom(msg.sender, address(this), boardFee), "Please pay full board fee.");
        Square purchaser;
        purchaser.address = msg.sender;
        squareBuyerz.push(purchaser);
        emit SquarePurchased(purchaser.address);
    }

    function initialize(bytes32 hostBoardDBHash, bytes32 hostBoardDBEntryHash) external onlyHost {
        boardDBEntryHash = hostBoardDBEntryHash;
        boardDBHash = hostBoardDBHash;
    }

    function collectPrize() winnerOnly {

        // if the winner collected their prize already, reject
        if(prizeCollectedByWinner(msg.sender)){
            _;
        } else{
            uint total = forwardWinners(msg.sender) + backwardWinners(msg.sender);
            if(total > 0 ){
                //
                if(feeToken){
                    IERC20(feeToken).transfer(msg.sender, total);
                } else {
                    address(msg.sender).transfer(total);
                }
                
                prizeCollectedByWinner(msg.sender) = true;
                prizesCollectedCount++;
                emit PrizeCollected(msg.sender, total);
            }
        }
    }

    function getWinners() public adminOrHostOnly {
        // require game status to be "STATUS_FINAL"
        // call to chainlink node 
        // get forward and backwards winners from orbitDB
        // place winner addresses and prize totals in forwardWinners and backwardWinner mappings
        // chainlink node call to get orbitDB hash for this factory
        uint256 specId = 1;
        Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfillWinnersRequest.selector);
        req.addUint("times", 10000);
        requestOracleData(req, payment);
    }

    // 1 winner
    function fulfillWinnersRequest(
        address winner1,
        uint256 winner1Total
    ) 
        pubic 
        recordChainlinkFulfillment(requestId)
    {
        winners(winner1) = winner1Total;
        winnerCount = 1;
    }

    // 2 winners
    function fulfillWinnersRequest(
        address winner1,
        uint256 winner1Total,
        address winner2,
        uint256 winner2Total
    ) 
        pubic 
        recordChainlinkFulfillment(requestId)
    {
        winners(winner1) = winner1Total;
        winners(winner2) = winner2Total;
        winnerCount = 2;
    }

    // 3 winners
    function fulfillWinnersRequest(
        address winner1,
        uint256 winner1Total,
        address winner2,
        uint256 winner2Total,
        address winner3,
        uint256 winner3Total
    ) 
        pubic 
        recordChainlinkFulfillment(requestId)
    {
        winners(winner1) = winner1Total;
        winners(winner2) = winner2Total;
        winners(winner3) = winner3Total;
        winnerCount = 3;
    }

    // 4 winners
    function fulfillWinnersRequest(
        address winner1,
        uint256 winner1Total,
        address winner2,
        uint256 winner2Total,
        address winner3,
        uint256 winner3Total,
        address winner4,
        uint256 winner4Total
    ) 
        pubic 
        recordChainlinkFulfillment(requestId)
    {
        winners(winner1) = winner1Total;
        winners(winner2) = winner2Total;
        winners(winner3) = winner3Total;
        winners(winner4) = winner4Total;
        winnerCount = 4;
    }

    // 5 winners
    function fulfillWinnersRequest(
        address winner1,
        uint256 winner1Total,
        address winner2,
        uint256 winner2Total,
        address winner3,
        uint256 winner3Total,
        address winner4,
        uint256 winner4Total,
        address winner5,
        uint256 winner5Total
    ) 
        pubic 
        recordChainlinkFulfillment(requestId)
    {
        winners(winner1) = winner1Total;
        winners(winner2) = winner2Total;
        winners(winner3) = winner3Total;
        winners(winner4) = winner4Total;
        winners(winner5) = winner5Total;
        winnerCount = 5;
    }

    // 6 winners
    function fulfillWinnersRequest(
        address winner1,
        uint256 winner1Total,
        address winner2,
        uint256 winner2Total,
        address winner3,
        uint256 winner3Total,
        address winner4,
        uint256 winner4Total,
        address winner5,
        uint256 winner5Total,
        address winner6,
        uint256 winner6Total
    ) 
        pubic 
        recordChainlinkFulfillment(requestId)
    {
        winners(winner1) = winner1Total;
        winners(winner2) = winner2Total;
        winners(winner3) = winner3Total;
        winners(winner4) = winner4Total;
        winners(winner5) = winner5Total;
        winners(winner6) = winner6Total;
        winnerCount = 6;
    }

    // 7 winners
    function fulfillWinnersRequest(
        address winner1,
        uint256 winner1Total,
        address winner2,
        uint256 winner2Total,
        address winner3,
        uint256 winner3Total,
        address winner4,
        uint256 winner4Total,
        address winner5,
        uint256 winner5Total,
        address winner6,
        uint256 winner6Total,
        address winner7,
        uint256 winner7Total
    ) 
        pubic 
        recordChainlinkFulfillment(requestId)
    {
        winners(winner1) = winner1Total;
        winners(winner2) = winner2Total;
        winners(winner3) = winner3Total;
        winners(winner4) = winner4Total;
        winners(winner5) = winner5Total;
        winners(winner6) = winner6Total;
        winners(winner7) = winner7Total;
        winnerCount = 7;
    }

    // 8 winners
    function fulfillWinnersRequest(
        address winner1,
        uint256 winner1Total,
        address winner2,
        uint256 winner2Total,
        address winner3,
        uint256 winner3Total,
        address winner4,
        uint256 winner4Total,
        address winner5,
        uint256 winner5Total,
        address winner6,
        uint256 winner6Total,
        address winner7,
        uint256 winner7Total,
        address winner8,
        uint256 winner8Total
    ) 
        pubic 
        recordChainlinkFulfillment(requestId)
    {
        winners(winner1) = winner1Total;
        winners(winner2) = winner2Total;
        winners(winner3) = winner3Total;
        winners(winner4) = winner4Total;
        winners(winner5) = winner5Total;
        winners(winner6) = winner6Total;
        winners(winner7) = winner7Total;
        winners(winner8) = winner8Total;
        winnerCount = 8;
    }

    function collectProfits() hostOnly {
        // withdraw profit which can be no more than 10% of total board
        require(winnerCount == prizesCollectedCount);
        IERC20(feeToken).transfer(msg.sender, IERC20(feeToken).balanceOf(address(this)));

    }
    
}