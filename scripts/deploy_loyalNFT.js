const hre = require("hardhat");

async function main() {
    const prices = [1000, 1010, 1020, 1030, 1040, 1050, 1060, 1070, 1080, 1090, 1100, 1130, 1160, 1190, 1220, 1250, 1280, 1310, 1340, 1370, 1400, 1450, 1500, 1550, 1600, 1650, 1700, 1750, 1800, 1850, 1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800]
    const loyalFactory = await hre.ethers.getContractFactory("LoyalNFT");
    const loyalNFTContract = await upgrades.deployProxy(loyalFactory, ["0x5596a9B46f6372CdC4c6a46148F85a9D02677346", "https://ipfs.filebase.io/ipfs/QmTYsMEZigCPu3ZjS4hT6Z7T8odshZJNyXvi2c9xcKkEBu", "0x3DDDD9daF716a9662b9f06fd570ED96Ef0800140", prices, "Loyal NFT", "LNFT", "0x7C626ebF454170F77F68C67A28A94BE4839cE917"]);

    console.log("loyal nft", loyalNFTContract.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });