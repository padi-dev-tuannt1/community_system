const hre = require("hardhat");

async function main() {
    const CPFactory = await hre.ethers.getContractAt("MembershipNFT","");
    const cpContract = await CPFactory.deploy("ContributionPoint", "CP");
    console.log("cp address", cpContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });