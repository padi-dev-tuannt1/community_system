const hre = require("hardhat");

async function main() {
    const MembershipNFT = await hre.ethers.getContractFactory(
        "MembershipNFT"
    );
    const membershipNFTContract = await MembershipNFT.deploy("CPtokenaddress", "Membership NFT", "MNFT", "DropAddress");

    await membershipNFTContract.deployed();

    console.log(membershipNFTContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });