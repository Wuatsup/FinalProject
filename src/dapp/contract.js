import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";
import FlightSuretyData from "../../build/contracts/FlightSuretyData.json";
import Config from "./config.json";
import Web3 from "web3";

export default class Contract {
  constructor(network, callback) {
    let config = Config[network];
       this.web3 = new Web3(
      new Web3.providers.WebsocketProvider(config.url.replace("http", "ws"))
    );

    this.flightSuretyApp = new this.web3.eth.Contract(
      FlightSuretyApp.abi,
      config.appAddress
    );
    this.flightSuretyData = new this.web3.eth.Contract(
      FlightSuretyData.abi,
      config.dataAddress
    );

    this.initialize(callback);
    this.owner = null;
    this.airlines = [];
    this.passengers = [];
  }

  initialize(callback) {
    this.web3.eth.getAccounts((error, accts) => {
      this.owner = accts[0];
     
      // this.flightSuretyData.methods.authorizeCaller(this.flightSuretyApp._address).send({from: this.owner});
     
      let counter = 0;

      while (this.airlines.length < 4) {
        this.airlines.push(accts[counter++]);
      }

      while (this.passengers.length < 5) {
        this.passengers.push(accts[counter++]);
      }

      callback();
    });
  }

  isOperational(callback) {
    let self = this;
    self.flightSuretyApp.methods
      .isOperational()
      .call({ from: self.owner }, callback);
  }

  getRegisteredAirlinesAccounts(callback) {
    let self = this;
    self.flightSuretyApp.methods
      .getRegisteredAirlinesAccounts()
      .call({ from: self.owner }, callback);
  }

  credit(callback) {
    this.flightSuretyApp.methods
      .getAccountCredit(this.passengers[0])
      .call({ from: this.passengers[0] }, (error, result) => {
        console.log("RESULT CREDIT", result, error);
        callback(error, this.web3.utils.fromWei(result, "ether"));
      });
  }

  // Need to modify to listen on insuranceAmount input
  buyTicket(
    airline,
    flightNumber,
    timestamp,
    insuranceAmount,
    passenger,
    callback
  ) {
    let self = this;
    let payload = {
      airline: airline,
      flight: flightNumber,
      timestamp: timestamp,
      price: self.web3.utils.toWei(insuranceAmount.toString(), "ether"),
    };

    self.flightSuretyApp.methods
      .purchaseInsurance(payload.airline, payload.flight, payload.timestamp)
      .send(
        {
          from: passenger,
          value: payload.price,
          gas: 4712388,
          gasPrice: 100000000000,
        },
        (error, result) => {
          // console.log(error);
          // console.log(result);
          callback(error, payload);
        }
      );
  }

  fetchFlightStatus(flight, callback) {
    let self = this;
    let payload = {
      airline: flight.airline,
      flight: flight.flight,
      timestamp: parseInt(flight.timestamp),
    };
    self.flightSuretyApp.methods
      .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
      .send({ from: self.owner }, (error, result) => {
        // console.log(error);
        // console.log(result);
        callback(error, payload);
      });
  }

  getFlightStatusCode(flight, callback) {
    let self = this;
    let payload = {
      airline: flight.airline,
      flight: flight.flight,
      timestamp: flight.timestamp,
    };

    self.flightSuretyApp.methods
      .getFlightStatusCode(payload.airline, payload.flight, payload.timestamp)
      .call({ from: self.owner }, callback);
  }

  payToInsuree() {
    let self = this;
  }

  // listen to event: flightStatusInfo
  // FlightStatusEvent(callback) {
  //     let self = this;

  //     self.flightSuretyApp.events.FlightStatusInfo({
  //             fromBlock: "latest"
  //         }, function (error, event) {
  //             if (error) {
  //                 console.log(error);
  //                 callback(error);
  //             } else {
  //                 // console.log(event);
  //             }
  //         })
  //         .on('data', function(event){
  //             return event;
  //         });
  // }

  redeemCredit(amount, passenger, callback) {
    let self = this;
    let withdrawlAmount = this.web3.utils.toWei(amount, "ether");
    self.flightSuretyApp.methods
      .withdraw(withdrawlAmount)
      .send({ from: passenger }, (error, result) => {
        console.log("ERROR", error);
        console.log("RESULT", result);
        callback(error, result);
      });
  }
}