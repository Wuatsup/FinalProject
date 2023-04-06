
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
const payment = web3.utils.toWei("10", "ether");


 
contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");
    
  });


  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  /****************************************************************************************/
  /* Airlines                                                            */
  /****************************************************************************************/

  it('There is a Airline registered', async() => {
    let testValue = await config.flightSuretyData.getNumberAirlinesRegistered.call();
    assert.equal(1,testValue, "No Airlines are Registered")
  });


  it('firstAirline should be registered', async() => {
    let testValue = await config.flightSuretyData.isAirlineregistered.call(config.firstAirline);
    assert.equal(true,testValue, "Airline is not first airline")
  });


  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
   // let registered = true;
   // try {
    await config.flightSuretyApp.registerAirline(config.testAddresses[2], {from: config.firstAirline});
    //console.log(`Address: ${config.testAddresses[2]}, ${accounts[2]}`);
   // }
   //     catch(e) {
   //     registered = false;<<<<<<<<<<<
   // }
    let result = await config.flightSuretyData.isAirlineregistered(config.testAddresses[2]); 
    assert.equal(false, result, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can be funded', async () => {
    let newAirline = config.testAddresses[2];
   // await config.flightSuretyApp.fundAirline(config.firstAirline, {from: config.firstAirline, value:payment});
    let isfunded = await config.flightSuretyData.isAirlinefunded.call(config.firstAirline); 
   assert.equal(true, isfunded, "Airline should be funded after providing 10 ether");

  });


 

 

});
