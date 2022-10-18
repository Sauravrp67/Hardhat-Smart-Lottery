//This is a script which updates the constant folders whenever we change something
// in the contract and deploy it

const { ethers } = require("hardhat")
const fs = require("fs")

const FRONT_END_ADDRESS_FILE = "../nextjs_smart_lottery/constants/contractAddress.json"

const FRONT_END_ABI_FILE = "../nextjs_smart_lottery/constants/abi.json"
module.exports = async function () {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Updating Front End")
        updateContractAddress()
        updateABI()
    }
}

async function updateContractAddress() {
    const raffle = await ethers.getContract("Raffle")

    const currentAddresses = JSON.parse(fs.readFileSync(FRONT_END_ADDRESS_FILE, "utf8"))
    const chainId = network.congfig.chainId.toString()

    if (chainId in currentAddresses) {
        if (!currentAddresses[chainId].includes(raffle.address)) {
            currentAddresses[chainId].push(raffle.address)
        }
    } else {
        currentAddresses[chainId] = [raffle.address]
    }
    fs.writeFileSync(FRONT_END_ADDRESS_FILE, JSON.stringify(currentAddresses))
}

async function updateABI() {
    const raffle = await ethers.getContract("Raffle")
    fs.writeFileSync(FRONT_END_ABI_FILE, raffle.interface.format(ethers.utils.FormatTypes.json))
}

module.exports.tags = ["all", "front-ends"]
