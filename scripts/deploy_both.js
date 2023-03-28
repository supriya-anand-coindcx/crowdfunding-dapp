const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log('Deploying contracts with the account: ' + deployer.address);

    // Deploy First
    const First = await hre.ethers.getContractFactory('CustomCrowdfundingToken');
    const first = await First.deploy("sachin", "SK");


    const Second = await hre.ethers.getContractFactory('CustomCrowdfunding');
    const second = await Second.deploy(first.address);

    console.log( "First: " + first.address );
    console.log( "Second: " + second.address );
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
})