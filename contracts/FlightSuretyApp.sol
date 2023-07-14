pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner; // Account used to deploy contract
    address private isAirline;
    address private FirstAirline = 0xf17f52151EbEF6C7334FAD080c5704D77216b732;

    FlightSuretyData flightSuretyData;

    uint256 public constant FUNDING_FEE = 10 ether;
    uint256 public constant INSURANCE_FEE = 1 ether;

    uint8 counterAirline = 0;

    address[] multiCallerArilines;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    mapping(bytes32 => Flight) private flights;

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
        // Modify to call data contract's status
        require(true, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAirline() {
        require(
            flightSuretyData.isAirlineregistered(msg.sender) == true,
            "airline is not registered"
        );
        _;
    }

    modifier requireFunded() {
        require(
            flightSuretyData.isAirlinefunded(msg.sender) == true,
            "airline is not funded"
        );
        _;
    }

    event InsurancePurchaseEvent(
        address airline,
        string flightNumber,
        uint timestamps,
        address passenger,
        uint amount
    );

    event InsurancePayoutCredit(
        address airline,
        string flightNumber,
        uint256 timestamp
    );

    event WithdrawalEvent(address account, uint256 amount);

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
     * @dev Contract constructor
     *
     */
    constructor(address dataContract) public {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);

        //flightSuretyData.initalizeAirline(FirstAirline);
        //flightSuretyData.registerAirline(FirstAirline);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public returns (bool) {
        return flightSuretyData.isOperational(); // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function fundAirline(address newAirline) public payable requireAirline {
        // Require Funding
        uint256 amount = msg.value;
        require(amount >= FUNDING_FEE, "Funding fee is required");
        flightSuretyData.fundAirline(newAirline);
    }

    function getRegisteredAirlinesAccounts()
        public
        view
        requireIsOperational
        returns (address[] memory)
    {
        return flightSuretyData.getRegisteredAirlinesAccounts();
    }

    /**
     * @dev Add an airline to the registration queue
     *
     */

    function IsAirlineRegistered(address _newAirline) returns (bool) {
        return (flightSuretyData.isAirlineregistered(_newAirline));
    }

    function IsAirlineFunded(address _newAirline) returns (bool) {
        return (flightSuretyData.isAirlinefunded(_newAirline));
    }

    function registerAirline(
        address newAirline
    )
        external
        requireAirline
        requireFunded
        returns (bool success, uint256 votes)
    {
        bool isDuplicate = false;

        require(
            !flightSuretyData.isAirlineregistered(newAirline),
            "Airline is already registered"
        );

        if (flightSuretyData.getNumberAirlinesRegistered() < 4) {
            flightSuretyData.registerAirline(newAirline);
            return (success, 0);
        }

        if (flightSuretyData.getNumberAirlinesRegistered() >= 4) {
            for (
                uint256 i = 0;
                i < flightSuretyData.getNumberAirlinesVotes(newAirline); //get number of votes
                i++
            ) {
                if (
                    flightSuretyData.getAirlineVoters(newAirline, i) ==
                    msg.sender
                ) {
                    //get voters for address save and copy data new array inside app account
                    isDuplicate = true;
                    break;
                }
            }
            require(!isDuplicate, "Caller has already voted.");

            flightSuretyData.pushAirlineVoter(msg.sender, newAirline);
            if (
                flightSuretyData.getNumberAirlinesVotes(newAirline) >=
                flightSuretyData.getNumberAirlinesRegistered() / 2
            ) {
                flightSuretyData.registerAirline(newAirline);
                return (
                    true,
                    flightSuretyData.getNumberAirlinesVotes(newAirline)
                );
            }
        }
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */

    function getFlightStatus(
        address airline,
        string memory flightNumber,
        uint256 timestamps
    ) public view returns (bool) {
        return
            flightSuretyData.getFlightStatus(airline, flightNumber, timestamps);
    }

    function purchaseInsurance(
        address airline,
        string memory flightNumber,
        uint timestamps
    ) public payable requireIsOperational {
        // Validate that flight exists or is registered
        require(
            getFlightStatus(airline, flightNumber, timestamps),
            "Flight does not exist or is not registered"
        );

        // Send ETH to data contract

        uint value = msg.value;
        flightSuretyData.buy(
            airline,
            flightNumber,
            msg.sender,
            value,
            timestamps
        );

        // Emit event
        emit InsurancePurchaseEvent(
            airline,
            flightNumber,
            timestamps,
            msg.sender,
            value
        );
    }

    function registerFlight(
        string flightNumber,
        uint256 timestamp
    ) external requireFunded {
        flightSuretyData.addflight(msg.sender, flightNumber, timestamp);
    }

    function withdraw(uint256 amount) public payable {
        // check whether caller is EOA (not contract account)
        // https://ethereum.stackexchange.com/questions/113962/what-does-msg-sender-tx-origin-actually-do-why
        /* require(
            msg.sender == tx.origin,
            "Passenger account is needed to make withdrawal"
        );
        */
        // Check that there is enough balance to withdraw
        require(
            getAccountCredit(msg.sender) >= amount,
            "Not enought balance in account"
        );

        // Send the payment
        flightSuretyData.payToInsuree(msg.sender, amount);

        // Emit event
        emit WithdrawalEvent(msg.sender, amount);
    }

    /*
    function creditInsurees(address _to, address _flight) external payable {
        require(
            flightSuretyData.isEligible(_flight, _to) == true,
            "Credit is not Eligible"
        );
        uint256 _amountEligible = flightSuretyData.amountEligible(_flight, _to);
        _amountEligible = (_amountEligible * 3) / 2;
        flightSuretyData.setPayed(_flight, _to, _amountEligible);
        _to.transfer(_amountEligible);
        _amountEligible = 0;
    }

*/
    function getAccountCredit(address account) public view returns (uint256) {
        return flightSuretyData.getAccountCredit(account);
    }

    /**
     * @dev Called after oracle has updated flight status
     *
     */
    function processFlightStatus(
        uint8 index,
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) internal {
        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        oracleResponses[key].isOpen = false;
        flightSuretyData.addFlightStatusCode(
            airline,
            flight,
            timestamp,
            statusCode
        );

        if (statusCode == 20) {
            flightSuretyData.creditInsurees(airline, flight, timestamp);
            emit InsurancePayoutCredit(airline, flight, timestamp);
        }
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        string flight,
        uint256 timestamp
    ) external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    function getFlightStatusCode(
        address airline,
        string memory flight,
        uint256 timestamp
    ) public view requireIsOperational returns (uint256) {
        return flightSuretyData.getFlightStatusCode(airline, flight, timestamp);
    }

    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp
    );

    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() external view returns (uint8[3]) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(index, airline, flight, timestamp, statusCode);
        }
    }

    function getFlightKey(
        address airline,
        string flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - nonce++), account)
                )
            ) % maxValue
        );

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    // endregion
}

contract FlightSuretyData {
    function initalizeAirline(address newAirline) external {}

    function isAirlineinitalized(
        address newAirline
    ) external view returns (bool) {}

    function registerAirline(address newAirline) external pure {}

    function isAirlineregistered(
        address newAirline
    ) external view returns (bool) {}

    function fundAirline(address newAirline) external {}

    function isAirlinefunded(address newAirline) external view returns (bool) {}

    function getNumberAirlinesRegistered() external view returns (uint8) {}

    function getRegisteredAirlinesAccounts()
        external
        view
        returns (address[] memory)
    {}

    function isFlighregistered(address _flight) external view returns (bool) {}

    function buy(
        address airline,
        string flight,
        address insuree,
        uint256 amount,
        uint256 timestamp
    ) external payable {}

    function addflight(
        address airlineAddress,
        string memory flight,
        uint256 timestamp
    ) {}

    function getFlightStatus(
        address airline,
        string flightNumber,
        uint256 timestamp
    ) external view returns (bool) {}

    function getAccountCredit(address account) external view returns (uint256);

    function isEligible(
        address _flight,
        address _insuree
    ) external view returns (bool) {}

    function amountEligible(
        address _flight,
        address _insuree
    ) returns (uint256) {}

    function setPayed(
        address _flight,
        address _insuree,
        uint256 _amount
    ) external {}

    function creditInsurees(
        address airline,
        string flightNumber,
        uint256 timestamp
    ) external {}

    function getNumberAirlinesVotes(
        address newAirline
    ) external view returns (uint256) {}

    function pushAirlineVoter(address Voter, address newAirline) external {}

    function getAirlineVoters(
        address newAirline,
        uint256 counter
    ) external view returns (address) {}

    function addFlightStatusCode(
        address airline,
        string newFlight,
        uint256 timestamp,
        uint256 statusCode
    ) external {}

    function getFlightStatusCode(
        address airline,
        string flight,
        uint256 timestamp
    ) external view returns (uint256) {}

    function isOperational() public view returns (bool) {}

    function payToInsuree(address account, uint256 amount) external payable {}
}
