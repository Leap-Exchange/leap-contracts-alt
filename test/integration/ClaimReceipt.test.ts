import { ADDRESS_ZERO, advanceBlock, advanceBlockTo, advanceTime, deploy, getBigNumber, prepare } from "../utilities";
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Source Side", function () {
  before(async function () {    
    await prepare(this, ["OptimismSrc", "@openzeppelin/contracts/interfaces/IERC20.sol:IERC20"])        
    await deploy(this, [    
      ["src", this.OptimismSrc, []],    
    ])    

  })   

  it("deposits ERC20 tokens to source contract", async function () {
    let transferData = {
      srcTokenAddress: ADDRESS_ZERO,
      destTokenAddress: ADDRESS_ZERO,
      destination: 
      amount:
      fee:
    }

    let initBal = this.alice
    this.src.connect(this.alice).deposit()
    const Source = await ethers.getContractFactory("Source");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });

  it("deposits gas tokens to source contract", async function () {
    let initBal = this.alice
    this.src.deposit()
    const Source = await ethers.getContractFactory("Source");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
