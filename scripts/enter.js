const { ethers } = require("hardhat")

async function enterRaffle() {
    const raffle = await ethers.getContract("Raffle")
    const entranceFee = await raffle.getEntranceFee()
    const tx = await raffle.entherRaffle({ value: entranceFee + 1 })
    await tx.wait(1)
    console.log(tx.hash)
    console.log("Entered")
}

enterRaffle()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
