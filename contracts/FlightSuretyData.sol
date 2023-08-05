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
        bool operational;
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

    struct flightInfo {
        bool isRegistered;
        uint256 totalPremium;
        uint256 statusCode;
    }

    struct InsureeInfo {
        uint256 insuranceAmount;
        uint256 payout;
    }

    address[] allAirlines = new address[](0);
    mapping(address => uint256) funding;
    mapping(address => uint256) amountavailable;

    event AirlineInit(address newAirline);
    event AirlineRegit(address newAirline);
    event AirlineFundet(address newAirline);
    event FlightRegit(address newFlight, address Airline);
    event Insured(address newInsuree, uint256 Amount);
    event Voted(address newAirline, address newVoter);

    uint8 counterAirlines;
    // address private FirstAirline = 0xF014343BDFFbED8660A9d8721deC985126f189F3;

    mapping(address => Airline) private airlines;
    mapping(address => mapping(bytes32 => flightInfo)) flights;
    mapping(address => mapping(bytes32 => address[])) insureeList;
    mapping(address => mapping(bytes32 => mapping(address => InsureeInfo))) insurees;
    mapping(address => uint256) accountCredit;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address _FirstAirlinetest) public {
        contractOwner = msg.sender;
        // initalizeAirline(_FirstAirline);
        // registerAirline(_FirstAirline);

        address _FirstAirline = msg.sender;

        airlines[_FirstAirline] = Airline({
            isInitialized: true,
            isRegistered: true,
            isFunded: true,
            operational: false,
            airline: _FirstAirline,
            votes: 0,
            multiCallerArilines: new address[](0)
        });
        counterAirlines++;
        allAirlines.push(_FirstAirline);
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

    function authorizeCaller(
        address contractAddress
    ) external requireContractOwner {}

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
            operational: false,
            airline: newAirline,
            votes: 0,
            multiCallerArilines: new address[](0)
        });
    }

    function isAirlineinitalized(
        address newAirline
    ) external view returns (bool) {
        return (airlines[newAirline].isInitialized);
    }

    function registerAirline(address newAirline) external {
        airlines[newAirline].isRegistered = true;
        counterAirlines++;
        allAirlines.push(newAirline);
        emit AirlineRegit(newAirline);
    }

    function isAirlineregistered(
        address newAirline
    ) external view returns (bool) {
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

    function getRegisteredAirlinesAccounts()
        external
        view
        requireIsOperational
        returns (address[] memory)
    {
        return allAirlines;
    }

    function getNumberAirlinesVotes(
        address newAirline
    ) external view returns (uint256) {
        return (airlines[newAirline].multiCallerArilines.length);
    }

    function pushAirlineVoter(address Voter, address newAirline) external {
        airlines[newAirline].votes++;
        airlines[newAirline].multiCallerArilines.push(Voter);
        emit Voted(newAirline, Voter);
    }

    function getAirlineVoters(
        address newAirline,
        uint256 counter
    ) external view returns (address) {
        return (airlines[newAirline].multiCallerArilines[counter]);
    }

    /**
     * @dev Buy insurance for a flight
     *
     */

    function isFlightregistered(address _flight) external view returns (bool) {
        // return (flights[_flight].isRegistered);
        return;
    }

    mapping(address => bytes32[]) flightList;

    function setPayed(
        address _flight,
        address _insuree,
        uint256 _amount
    ) external {
        //flights[_flight].isPayed[_insuree] = true;
        // emit Withdraw(_insuree, _amount, _flight);
    }

    function isEligible(
        address _flight,
        address _insuree
    ) external view returns (bool) {
        /*  require(
            flights[_flight].isRegistered == true,
            "Flight is not registered"
        );
        require(
            flights[_flight].isPayed[_insuree] != true,
            "Flight is already received insurance payout"
        );
        require(
            flights[_flight].amountpayed[_insuree] != 0,
            "Insuree is not registered for the flight"
        );
        require(flights[_flight].isDelayed == true, "Flight is not delayed");
    */
        return (true);
    }

    function buy(
        address airline,
        string flight,
        address insuree,
        uint256 amount,
        uint256 timestamp
    ) external payable requireIsOperational {
        // Increment the total premium collected for a flight
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        flights[airline][key].totalPremium = flights[airline][key]
            .totalPremium
            .add(amount);

        // Add the new insuree to the insuree list
        insureeList[airline][key].push(insuree);

        insurees[airline][key][insuree] = InsureeInfo({
            insuranceAmount: amount,
            payout: 0
        });
    }

    function payToInsuree(
        address account,
        uint256 amount
    ) public payable requireIsOperational {
        // Before the payment, substract to the credit of the insuree
        accountCredit[account] = accountCredit[account].sub(amount);
        // Transfer the amount
        account.transfer(amount);
    }

    function addflight(
        address airlineAddress,
        string memory flight,
        uint256 timestamp
    ) {
        //  flights[_flight].airline = _airlines;
        //  flights[_flight].isRegistered = true;
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        flightList[airlineAddress].push(key);
        flights[airlineAddress][key].isRegistered = true;
        flights[airlineAddress][key].totalPremium = 0;
        flights[airlineAddress][key].statusCode = 20;

        //  emit FlightRegit(flight, airlineAddress);
    }

    function getFlightStatus(
        address airline,
        string flightNumber,
        uint256 timestamp
    ) external view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(flightNumber, timestamp));
        bool result = flights[airline][key].isRegistered;
        return result;
    }

    function addFlightStatusCode(
        address airline,
        string flight,
        uint256 timestamp,
        uint256 code
    ) external {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        flights[airline][key].statusCode = code;
    }

    function getFlightStatusCode(
        address airline,
        string flight,
        uint256 timestamp
    ) external view returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        uint statusCode = flights[airline][key].statusCode;
        return statusCode;
    }

    function amountEligible(
        address _flight,
        address _insuree
    ) returns (uint256) {
        // return (flights[_flight].amountpayed[_insuree]);
        return;
    }

    function getAccountCredit(
        address account
    ) external view requireIsOperational returns (uint256) {
        return accountCredit[account];
    }

    function creditInsurees(
        address airline,
        string flightNumber,
        uint256 timestamp
    ) external requireIsOperational {
        bytes32 key = keccak256(abi.encodePacked(flightNumber, timestamp));
        address[] creditAccounts = insureeList[airline][key];
        uint256 accountsLength = creditAccounts.length;

        require(accountsLength > 0, "No insurees for the delayed flight");

        for (uint256 i = 0; i < accountsLength; i++) {
            uint256 creditAmount = 0;
            address account = creditAccounts[i];
            creditAmount = insurees[airline][key][account]
                .insuranceAmount
                .mul(3)
                .div(2);

            // update insureeInfo of flight
            insurees[airline][key][account].payout = creditAmount;

            // update individal passenger account credit
            accountCredit[account] = accountCredit[account].add(creditAmount);
        }
    }

    function pay() external pure {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */

    function getFunding(
        address account
    ) public view requireIsOperational returns (uint256) {
        uint256 funds = funding[account];
        return funds;
    }

    function fund(address account) public payable requireIsOperational {
        funding[account] = msg.value;
        setAirlineOperationalStatus(account, true);
    }

    function setAirlineOperationalStatus(
        address airlineAddress,
        bool status
    ) private requireIsOperational {
        airlines[airlineAddress].operational = status;
    }

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
        fund(msg.sender);
    }
}
