
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
const payment = web3.utils.toWei("10", "ether");






 
contract('Flight Surety Tests', async (accounts) => {

  var config;
  let _firstAirline = accounts[1];
  let _secondAirline = accounts[2];;
  let _thirdAirline = accounts[3];;
  let _fourthAirline = accounts[4];
  let _fivedAirline =  accounts[5];

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
          await config.flightSuretyData.setOperatingStatus(false, { from: _secondAirline });
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
    console.log(`Airlines Registered: ${config.testAddresses[1]}, ${testValue}}`);
  });


  /*it('firstAirline should be registered', async() => {
    let testValue = await config.flightSuretyData.isAirlineregistered.call(config.firstAirline);
    assert.equal(true,testValue, "Airline is not first airline")
  });*/


  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
      try {
        await config.flightSuretyApp.registerAirline(_secondAirline, {from: config.fivedAirline});
      }
      catch(e) 
      {
      
     }

      let result = await config.flightSuretyData.isAirlineregistered(_secondAirline); 
      assert.equal(false, result, "Airline should not be able to register another airline if it hasn't provided funding");
  });

  it('(airline) can register an Airline  if it is funded', async () => {
    await config.flightSuretyApp.registerAirline(_secondAirline);
    let result = await config.flightSuretyData.isAirlineregistered(_secondAirline); 
    assert.equal(true, result, "Funded Airline can not register a new airline");
    let airlines = await config.flightSuretyData.getNumberAirlinesRegistered.call();
    console.log(`Airlines Registered: ${_secondAirline}, ${airlines}}`);  
});

  it('4 airlines can be registered without voting', async () => {

    await config.flightSuretyApp.registerAirline(_thirdAirline);
    let result = await config.flightSuretyData.isAirlineregistered(_thirdAirline); 
    let airlines = await config.flightSuretyData.getNumberAirlinesRegistered.call();
    assert.equal(true, result, "Funded Airline can not register a new airline");
    console.log(`Airlines Registered: ${config.testAddresses[3]},${_thirdAirline}, ${airlines}}`);


    await config.flightSuretyApp.registerAirline(_fourthAirline);
    let result1 = await config.flightSuretyData.isAirlineregistered(_fourthAirline); 
    let airlines1 = await config.flightSuretyData.getNumberAirlinesRegistered.call();
    assert.equal(true, result1, "Funded Airline can not register a new airline");
    console.log(`Airlines Registered: ${config.testAddresses[4]},${_fourthAirline}, ${airlines1}}`);
  }
);


  it('(airline) can be funded', async () => {
    await config.flightSuretyApp.fundAirline(config.firstAirline, {value:payment});
    let isfunded = await config.flightSuretyData.isAirlinefunded.call(config.firstAirline); 
   assert.equal(true, isfunded, "Airline should be funded after providing 10 ether");

  });

it('registered airline can only be registered once', async () => {
    let error = false;
   
    try {
    await config.flightSuretyApp.registerAirline(_secondAirline);
    }
    catch(e){
        error = true;
    }
    assert.equal(true, error, "Airline was already registered");
    let airlines = await config.flightSuretyData.getNumberAirlinesRegistered.call();
    console.log(`Airlines Registered: ${_secondAirline}, ${airlines}}`); 

});


it('over 4 airlines can be added through voting', async () => {
    
    await config.flightSuretyApp.fundAirline(_secondAirline, { value:payment});
    await config.flightSuretyApp.fundAirline(_thirdAirline, { value:payment});
    await config.flightSuretyApp.fundAirline(_thirdAirline, { value:payment});
    await config.flightSuretyApp.fundAirline(_fourthAirline, { value:payment});

    let regAirlines= await config.flightSuretyData.getNumberAirlinesRegistered.call();
    let voters = await config.flightSuretyData.getNumberAirlinesVotes(config.testAddresses[5]);
    console.log(`Votes: ${voters}}`);
    console.log(`Airlines: ${regAirlines}`);
    
    await config.flightSuretyApp.registerAirline(config.testAddresses[5]); 
    regAirlines= await config.flightSuretyData.getNumberAirlinesRegistered.call();
    voters = await config.flightSuretyData.getNumberAirlinesVotes(config.testAddresses[5]);
    console.log(`Votes: ${voters}}`);
    console.log(`Airlines: ${regAirlines}`);
   
    await config.flightSuretyApp.registerAirline(config.testAddresses[5], {from: _secondAirline});
    regAirlines= await config.flightSuretyData.getNumberAirlinesRegistered.call();
    voters = await config.flightSuretyData.getNumberAirlinesVotes(config.testAddresses[5]);
    console.log(`Votes: ${voters}}`);
    console.log(`Airlines: ${regAirlines}`);
   
    let airlines = await config.flightSuretyData.getNumberAirlinesRegistered.call();
    let result = await config.flightSuretyData.isAirlineregistered(config.testAddresses[5]); 
    assert.equal(true, result, "Airline should be registered after 50% of the votes");
    console.log(`Airlines Registered: ${config.testAddresses[5]}, ${airlines}}`);
    
    });

});
