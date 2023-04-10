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

    struct Flights {
        bool isDelayed;
        bool isRegistered;
        address airline;
        address[] hasInsurance;
        mapping(address => uint256) amountpayed;
        mapping(address => bool) isPayed;
    }

    event AirlineInit(address newAirline);
    event AirlineRegit(address newAirline);
    event AirlineFundet(address newAirline);
    event FlightRegit(address newFlight, address Airline);
    event Insured(address newInsuree, uint256 Amount);
    event Voted(address newAirline, address newVoter);
    event Withdraw(address Insuree, uint256 Amount, address Flight);

    uint8 counterAirlines;
    address private FirstAirline = 0xF014343BDFFbED8660A9d8721deC985126f189F3;

    mapping(address => Airline) private airlines;
    mapping(address => Flights) private flights;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address _FirstAirline) public {
        contractOwner = msg.sender;
        // initalizeAirline(_FirstAirline);
        // registerAirline(_FirstAirline);

        airlines[_FirstAirline] = Airline({
            isInitialized: true,
            isRegistered: true,
            isFunded: false,
            airline: _FirstAirline,
            votes: 0,
            multiCallerArilines: new address[](0)
        });
        counterAirlines++;
    }

    function tet() external {}

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
    function setOperatingStatus(bool mode) public requireContractOwner {
        operational = mode;
    }

    function authorizeCaller(address contractAddress)
        external
        requireContractOwner
    {}

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function initalizeAirline(address newAirline) public {
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

    function isFlightregistered(address _flight) external view returns (bool) {
        return (flights[_flight].isRegistered);
    }

    function setPayed(
        address _flight,
        address _insuree,
        uint256 _amount
    ) external {
        flights[_flight].isPayed[_insuree] = true;
        emit Withdraw(_insuree, _amount, _flight);
    }

    function isEligible(address _flight, address _insuree)
        external
        view
        returns (bool)
    {
        require(
            flights[_flight].isRegistered == true,
            "Flight is not registered"
        );
        require(
            flights[_flight].isPayed[_insuree] != true,
            "Flight is not registered"
        );
        require(
            flights[_flight].amountpayed[_insuree] != 0,
            "Insuree is not registered for the flight"
        );
        require(flights[_flight].isDelayed == true, "Flight is not delayed");

        return (true);
    }

    function buy(
        address _flight,
        address _insured,
        uint256 _amount
    ) external {
        flights[_flight].hasInsurance.push(_insured);
        flights[_flight].amountpayed[_insured] = _amount;
        emit Insured(_insured, _amount);
    }

    function addflight(address _flight, address _airlines) {
        flights[_flight].airline = _airlines;
        flights[_flight].isRegistered = true;
        emit FlightRegit(_flight, _airlines);
    }

    function amountEligible(address _flight, address _insuree)
        returns (uint256)
    {
        return (flights[_flight].amountpayed[_insuree]);
    }

    //Funktionalität der Versicherung nachschauen, z.B. hinterlegt die Airline geld für dei Versicherung?

    /**
     *  @dev Credits payouts to insurees
     */

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
        string memory _flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, _flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable {
        fund();
    }
}
