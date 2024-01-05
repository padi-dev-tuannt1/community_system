const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("CP Token", async () => {
    let owner;
    let addr1;
    let addr2;
    let contributionContract;
    let updatePointContract;
    let deadline;
    const createSignature = async (
        cpAddress,
        signer,
        _requester,
        _amount,
        _deadline,
        _nonce
    ) => {
        let domain = {
            name: "CP",
            version: "1",
            chainId: 1337,
            verifyingContract: cpAddress,
        };

        let types = {
            params: [
                { name: "_requester", type: "address" },
                { name: "_amount", type: "uint256" },
                { name: "_deadline", type: "uint256" },
                { name: "_nonce", type: "uint256" },
            ],
        };

        let value = {
            _requester,
            _amount,
            _deadline,
            _nonce
        };

        return signer._signTypedData(domain, types, value);
    };

    before(async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        deadline = Math.floor(Date.now() / 1000 + 5 * 60);

        contributionContract = await (await ethers.getContractFactory("ContributionPoint")).deploy("Contribution Point", "CP")
        await contributionContract.addToWhitelist([owner.address])
        await contributionContract.addToWhitelist([addr1.address])

    });

    describe("Mint token", () => {
        let signature;
        before(async () => {
            signature = await createSignature(
                contributionContract.address,
                owner,
                owner.address,
                20,
                deadline,
                15
            );

            const tx = await contributionContract.mint(signature, {
                requester: owner.address,
                amount: 20,
                deadline: deadline,
                nonce: 15,
            })
            await tx.wait();
        });

        it("Balance of requester is greater than zero", async () => {
            expect(await contributionContract.balanceOf(owner.address)).to.equal("20000000000000000000");
        });

        it("Fail if signature is invalid", async () => {
            signature = await createSignature(
                contributionContract.address,
                owner,
                owner.address,
                10,
                deadline,
                14
            );
            await expect(contributionContract.mint(signature, {
                requester: owner.address,
                amount: 10,
                deadline: deadline,
                nonce: 15,
            })).revertedWith("Not in whitelist")
        });

    });

    describe("Burn token", () => {

        it("Fail if burner is not in whitelist", async () => {
            await expect(contributionContract.connect(addr2).burn(owner.address, 10)).revertedWith("Not in whitelist");
        });

        it("Burn success", async () => {
            await contributionContract.connect(addr1).burn(owner.address, ethers.utils.parseEther("10"))
            expect(await contributionContract.balanceOf(owner.address)).to.equal("10000000000000000000");
        })
    });
});
