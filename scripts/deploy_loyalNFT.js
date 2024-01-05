const hre = require("hardhat");

async function main() {

    const loyalFactory = await hre.ethers.getContractFactory("LoyalNFT");
    const loyalNFTContract = await loyalFactory.deploy("0x5596a9B46f6372CdC4c6a46148F85a9D02677346", "https://ipfs.filebase.io/ipfs/QmTYsMEZigCPu3ZjS4hT6Z7T8odshZJNyXvi2c9xcKkEBu");

    console.log("loyal nft", loyalNFTContract.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });