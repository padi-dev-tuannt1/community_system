const hre = require("hardhat");

async function main() {
    const NFTStake = await hre.ethers.getContractFactory("NFTStake");
    const NFTStakeProxy = await upgrades.deployProxy(NFTStake, ["0x4D65A34bAf39489C0E4d5Ab825ee4b8f43D022B1", "0x09b21916D76F1c96237c6e1442193b3a86A41F6E", "0x7C626ebF454170F77F68C67A28A94BE4839cE917"], {
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