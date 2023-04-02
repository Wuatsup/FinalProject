pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    struct Airline {
        bool isInitialized;
        bool isRegistered;
        bool isFunded;
        address airline;
        uint8 votes;
        address[] multiCallerArilines;
    }

    event AirlineInit(address newAirline);
    event AirlineRegit(address newAirline);
    event AirlineFundet(address newAirline);
    event Voted(address newAirline, address newVoter);

    uint8 counterAirlines;

    mapping(address => Airline) private airlines;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor() public {
        contractOwner = msg.sender;

        airlines[contractOwner] = Airline({
            isInitialized: true,
            isRegistered: false,
            isFunded: false,
            airline: contractOwner,
            votes: 0,
            multiCallerArilines: new address[](0)
        });
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function initalizeAirline(address newAirline) external {
        airlines[newAirline] = Airline({
            isInitialized: true,
            isRegistered: false,
            isFunded: false,
            airline: newAirline,
            votes: 0,
            multiCallerArilines: new address[](0)
        });
    }

    function isAirlineinitalized(address newAirline)
        external
        view
        returns (bool)
    {
        return (airlines[newAirline].isInitialized);
    }

    function registerAirline(address newAirline) external {
        airlines[newAirline].isRegistered = true;
        counterAirlines++;
        emit AirlineRegit(newAirline);
    }

    function isAirlineregistered(address newAirline)
        external
        view
        returns (bool)
    {
        return (airlines[newAirline].isRegistered);
    }

    function fundAirline(address newAirline) external {
        airlines[newAirline].isFunded = true;
        emit AirlineFundet(newAirline);
    }

    function isAirlinefunded(address newAirline) external view returns (bool) {
        return (airlines[newAirline].isFunded);
    }

    function getNumberAirlinesRegistered() external view returns (uint8) {
        return (counterAirlines);
    }

    function getNumberAirlinesVotes(address newAirline)
        external
        view
        returns (uint256)
    {
        return (airlines[newAirline].multiCallerArilines.length);
    }

    function pushAirlineVoter(address Voter, address newAirline) external {
        airlines[newAirline].votes++;
        airlines[newAirline].multiCallerArilines.push(Voter);
        emit Voted(newAirline, Voter);
    }

    function getAirlineVoters(address newAirline, uint256 counter)
        external
        view
        returns (address)
    {
        return (airlines[newAirline].multiCallerArilines[counter]);
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy() external payable {}

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees() external pure {}

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay() external pure {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund() public payable {}

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable {
        fund();
    }
}
