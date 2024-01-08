const hre = require("hardhat");

async function main() {
    const NFTStake = await hre.ethers.getContractFactory("NFTStake");
    const NFTStakeProxy = await upgrades.deployProxy(NFTStake, ["0x137c1176C15FCc03303522d7229d21e4f5Df4bc7", "0x137c1176C15FCc03303522d7229d21e4f5Df4bc7"], {
        kind: "uups",
    });

    console.log(NFTStakeProxy.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });