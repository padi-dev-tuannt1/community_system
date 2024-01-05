const { randomBytes: nodeRandomBytes } = require("crypto");
const { ethers } = require("ethers");

const SeededRNG = require("./seeded-rng");

const GAS_REPORT_MODE = process.env.REPORT_GAS;

let randomBytes;
if (GAS_REPORT_MODE) {
    const srng = SeededRNG.create("gas-report");
    randomBytes = srng.randomBytes;
} else {
    randomBytes = (n) => nodeRandomBytes(n).toString("hex");
}

const randomHex = (bytes = 32) => `0x${randomBytes(bytes)}`;

const getInterfaceID = (contractInterface) => {
    let interfaceID = ethers.constants.Zero;
    const functions = Object.keys(contractInterface.functions);
    for (let i = 0; i < functions.length; i++) {
        interfaceID = interfaceID.xor(contractInterface.getSighash(functions[i]));
    }
    return interfaceID;
};

module.exports = { randomHex, getInterfaceID };
