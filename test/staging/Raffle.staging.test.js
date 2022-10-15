const { assert, expect } = require("chai")
const { getNamedAccounts, deployments, ethers, network } = require("hardhat")
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

developmentChains.includes(network.name)
    ? describe.skip
    : describe("Raffle Staging Test", function () {
          let raffle, raffleEntranceFee, deployer

          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              raffle = await ethers.getContract("Raffle", deployer)
              raffleEntranceFee = await raffle.getEntranceFee()
          })
          describe("fulfillRandomWords", function () {
              it("Works with live chainlink keepers and chainlink VRF, we get a random winner", async function () {
                  const startingTimeStamp = await raffle.getLatestTimeStamp()
                  const accounts = await ethers.getSigners()

                  await new Promise(async (resolve, reject) => {
                      raffle.once("WinnerPicked", async () => {
                          console.log("WinnerPicked event fired!!!")
                          try {
                              const recentWinner = await raffle.getRecentWinner()
                              const raffleState = await raffle.getRaffleState()
                              const winnerEndingBalance = await accounts[0].getBalance()
                              const endingTimeStamp = await raffle.getLatestTimeStamp()

                              await expect(raffle.getPlayer(0)).to.be.reverted
                              assert(endingTimeStamp > startingTimeStamp)
                              assert.equal(raffleState, 0)
                              assert.equal(recentWinner.toString(), accounts[0].address)
                              console.log(`Ending Balance: ${winnerEndingBalance.toString()}`)
                              console.log(`Raffle Entrance fee : ${raffleEntranceFee.toString()}`)
                              //assert.equal(
                              //winnerEndingBalance.toString(),
                              //winnerStartingBalance.add(raffleEntranceFee).toString()
                              //)
                          } catch (error) {
                              console.log(error)
                              reject(error)
                          }
                          resolve()
                      })
                      console.log("Entering Raffle")
                      const txResponse = await raffle.enterRaffle({ value: raffleEntranceFee })
                      await txResponse.wait(1)
                      console.log("Ok time to wait")
                      const winnerStartingBalance = await accounts[0].getBalance()
                  })
              })
          })
      })
