const hre = require("hardhat");

async function main() {
    // const CPFactory = await hre.ethers.getContractFactory("CPToken");
    // const cpContract = await CPFactory.deploy();

    const loyalFactory = await hre.ethers.getContractFactory("USDC");
    const loyalNFTContract = await loyalFactory.deploy();

    // console.log("cp address", cpContract.address);
    console.log("loyal nft", loyalNFTContract.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });