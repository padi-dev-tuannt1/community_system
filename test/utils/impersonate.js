const { faucet } = require("./faucet");

const impersonate = async (address, provider) => {
    await provider.send("hardhat_impersonateAccount", [address]);
    await faucet(address, provider);
};

const stopImpersonation = async (address, provider) => {
    await provider.send("hardhat_stopImpersonatingAccount", [address]);
};

const whileImpersonating = async (address, provider, fn) => {
    await impersonate(address, provider);
    const impersonatedSigner = await provider.getSigner(address);
    const result = await fn(impersonatedSigner);
    await stopImpersonation(address, provider);
    return result;
};

module.exports = { impersonate, stopImpersonation, whileImpersonating };
