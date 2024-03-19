const hre = require("hardhat");

async function main() {
    const NFTStakeFactory = await hre.ethers.getContractFactory("NFTStake");
    await upgrades.upgradeProxy(
        "0x1d7b9C2993fb97bAcDB51da973e6C1502411913d",
        NFTStakeFactory,
        {
            kind: "uups",
        }
    );
    console.log("Box upgraded");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
