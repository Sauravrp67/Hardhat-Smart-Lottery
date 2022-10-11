const { assert, expect } = require("chai")
const { getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Raffle", async function () {
          let raffle, vrfCoordinatorV2Mock
          const chainId = network.config.chainId

          beforeEach(async function () {
              const { deployer } = await getNamedAccounts
              await deployments.fixture(["all"])
              raffle = await ethers.getContract("Raffle", deployer)
              vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock", deployer)
          })

          describe("constructor", async function () {
              it("Initialized the raffle correctly", async function () {
                  const raffleState = await raffle.getRaffleState()
                  const interval = await raffle.getInterval()
                  assert.equal(raffleState.toString(), "0")
                  console.log(chainId)
                  assert.equal(interval.toString(), networkConfig[chainId]["Interval"])
              })
          })
          describe("EnterRaffle", async function () {
              it("Reverts if you don't pay enough", async function () {
                  await expect(raffle.enterRaffle()).to.be.revertedWithCustomError(
                      raffle,
                      "Raffle__NoEnoughETHEntered"
                  )
              })
          })
      })
