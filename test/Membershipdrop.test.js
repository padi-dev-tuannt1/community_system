const { expect } = require("chai");
const { ethers, network } = require("hardhat");

const { getInterfaceID, randomHex } = require("./utils/encoding");
const { faucet } = require("./utils/faucet");
const { whileImpersonating } = require("./utils/impersonate");

describe("MembershipDrop", function () {
    const { provider } = ethers;
    let membershipdrop;
    let token;
    let owner;
    let creator;
    let minter;
    let minter2;
    let publicDrop;
    let CPtoken;

    after(async () => {
        await network.provider.request({
            method: "hardhat_reset",
        });
    });

    before(async () => {
        // Set the wallets
        owner = new ethers.Wallet(randomHex(32), provider);
        creator = new ethers.Wallet(randomHex(32), provider);
        minter = new ethers.Wallet(randomHex(32), provider);
        minter2 = new ethers.Wallet(randomHex(32), provider);

        // Add eth to wallets
        for (const wallet of [owner, minter, minter2, creator]) {
            await faucet(wallet.address, provider);
        }
        // Deploy MembershipDrop
        const MembershipDrop = await ethers.getContractFactory(
            "MembershipDrop",
            owner
        );
        membershipdrop = await MembershipDrop.deploy();
        const contributionPoint = await ethers.getContractFactory("CPToken", owner);
        CPtoken = await contributionPoint.deploy();
        CPtoken.mint(10000);
        CPtoken.connect(minter).mint(10000);
    });

    beforeEach(async () => {
        // Deploy token
        const MembershipNFT = await ethers.getContractFactory(
            "MembershipNFT",
            owner
        );
        token = await MembershipNFT.deploy(
            CPtoken.address,
            "",
            "",
            membershipdrop.address
        );

        publicDrop = {
            mintPrice: "0",
            maxTotalMintableByWallet: 2,
            startTime: Math.round(Date.now() / 1000) - 100,
            endTime: Math.round(Date.now() / 1000) + 2000,
            feeBps: 0,
            restrictFeeRecipients: false,
            contractERC20: ethers.constants.AddressZero,
        };
        const feeRecipient = new ethers.Wallet(randomHex(32), provider);
        const config = {
            maxSupply: 100,
            membershipDropImpl: membershipdrop.address,
            publicDrop,
        };

        await token.connect(owner).multiConfigure(config);
        await membershipdrop
            .connect(minter)
            .mintPublic(
                token.address,
                feeRecipient.address,
                ethers.constants.AddressZero,
                1,
                { value: publicDrop.mintPrice }
            );
        await CPtoken.connect(minter).approve(token.address, ethers.utils.parseEther("100000000"));
    });

    it("Should only let allowed membershipdrop call mintDrop", async () => {
        await expect(
            token.connect(owner).mintDrop(minter.address)
        ).to.be.revertedWith("OnlyAllowedDrop");
    });

    it("Should be able to use the multiConfigure method with enough parameters", async () => {

        await membershipdrop
            .connect(minter2)
            .mintPublic(
                token.address,
                ethers.constants.AddressZero,
                ethers.constants.AddressZero,
                1,
                { value: publicDrop.mintPrice }
            );
    });

    it("cannot transfer membership NFT", async () => {
        await expect(token.connect(minter).transferFrom(minter.address, owner.address, 1)).to.be.revertedWith("MembershipNFT: Can not transfer membership NFT");
    });

    it("cannot update membership NFT if level is invalid", async () => {
        await expect(token.connect(minter).updateLevel(1, 13)).to.be.revertedWith("MembershipNFT: Invalid level");
    });

    it("cannot update membership NFT if you are not the owner", async () => {
        await expect(token.connect(minter2).updateLevel(1, 1)).to.be.revertedWith("MembershipNFT: You are not owner of NFT");
    });

    it("cannot update membership NFT if you don't have enough CP token", async () => {
        await expect(token.connect(minter).updateLevel(1, 10)).to.be.revertedWith("NotEnoughCP");
    });

    it("change token URI when update level", async () => {
        expect(await token.tokenURI(1)).to.equal("https://ipfs.filebase.io/ipfs/Qme1z6mZQ74ZRJVoMRmth51e7x6tcSVewNitHzvvUxGuvW")

        await token.connect(minter).updateLevel(1, 1);
        expect(await token.tokenURI(1)).to.equal("https://ipfs.filebase.io/ipfs/QmZeaXP4TEB6LKRpPqBRAMD5wTeZS1TpGVsmurJFwZ74Jn")

        await token.connect(minter).updateLevel(1, 2);
        expect(await token.tokenURI(1)).to.equal("https://ipfs.filebase.io/ipfs/QmX6PMYkZJQGNUePXUyMnVJ2oD5FKsFbWMQzFsy5rmjFQ1")
        console.log(await token.getLevelURIs());
    });
});
