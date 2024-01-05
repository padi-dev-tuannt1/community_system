const { parseEther } = require("@ethersproject/units");
const { ethers } = require("hardhat");

const { randomHex } = require("./encoding");

const TEN_THOUSAND_ETH = parseEther("10000").toHexString().replace("0x0", "0x");

const faucet = async (address, provider) => {
    await provider.send("hardhat_setBalance", [address, TEN_THOUSAND_ETH]);
};

const getWalletWithEther = async () => {
    const wallet = new ethers.Wallet(randomHex(32), ethers.provider);
    await faucet(wallet.address, ethers.provider);
    return wallet;
};

module.exports = { faucet, getWalletWithEther };
