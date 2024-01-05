const hre = require("hardhat");

async function main() {
    const MembershipDrop = await hre.ethers.getContractFactory(
        "MembershipDrop"
    );
    const membershipDrop = await MembershipDrop.deploy();

    await membershipDrop.deployed();

    console.log(membershipDrop.address);//0xC573Fe25727C0cE74bf06e70843707551FccCfc4
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
