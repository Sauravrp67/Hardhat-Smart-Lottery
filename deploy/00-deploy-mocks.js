const { developmentChains, networkConfig } = require("../helper-hardhat-config")

const BASE_FEE = ethers.utils.parseEther("0.25") // 0.25 is the premium. It costs 0.25 LINK to requiest on random number from the VRF
const GAS_PRICE_LINK = "100000000"
// link per gas //calculated value based on the gas price of the chain/
//ETH Price $1,000,000,000
//Chainlink Nodes pay the gas fee to give us randomness & do external execution
// So they price of requests change based on the price of gas

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const args = [BASE_FEE, GAS_PRICE_LINK]

    if (developmentChains.includes(network.name)) {
        log("Local Network detected!! Deploying mocks....")
        log(`The address deploying is: ${deployer}`)
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            args: args,
            log: true,
        })
        log("Mocks Deployed!!")
        log("------------------------------------------------")
    }
}

module.exports.tags = ["all", "mocks"]
