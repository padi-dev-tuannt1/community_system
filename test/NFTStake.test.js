const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("NFT stake", async () => {
    let owner;
    let addr1;
    let addr2;
    let nftStakeContract;
    let nftContract;
    let rewardToken;
    let tokenIds;
    let season;
    before(async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        rewardToken = await (await ethers.getContractFactory("MEWA")).deploy();
        nftContract = await (await ethers.getContractFactory("SimpleERC721")).deploy();

        const nftStakeFactory = await ethers.getContractFactory("NFTStake");
        nftStakeContract = await upgrades.deployProxy(nftStakeFactory, [nftContract.address, rewardToken.address], { kind: "uups" })

        for (i = 0; i < 2; i++) { nftContract.mint(addr1.address) };
        nftContract.mint(owner.address);
        tokenIds = [1, 2, 3];
        season = 1;

        rewardToken.mint(100000);
    });

    describe("Stake NFT", () => {

        it("Fail if you are not owner of NFT", async () => {
            await nftContract.connect(addr1).setApprovalForAll(nftStakeContract.address, true);
            await expect(nftStakeContract.connect(addr1).stake(tokenIds, season)).to.revertedWith("NotItemOwner");
        });

        it("Stake NFT successfully", async () => {
            await nftStakeContract.connect(addr1).stake([0, 1], season);
            expect(await nftStakeContract.stakeInfos(0)).to.have.property('owner', addr1.address)
            expect(await nftStakeContract.stakeInfos(0)).to.have.property('status', 1)
        })

        it("Fail if NFT is already stake", async () => {
            await expect(nftStakeContract.connect(addr1).stake(tokenIds, season)).to.revertedWith("Already stake")
        })
    });

    describe("create reward", () => {
        it("Fail if length of stakers and rewards mismatch", async () => {
            await expect(nftStakeContract.createReward([addr1.address, addr2.address], [10], 100000, 1)).to.revertedWith("Length mismatch")
        })

        it("Fail if staker is zero address", async () => {
            await expect(nftStakeContract.createReward([addr1.address, ethers.constants.AddressZero], [10, 10], 100000, 1)).to.revertedWith("Staker cannot be zero address")
        })

        it("Fail if staker is itself", async () => {
            await expect(nftStakeContract.createReward([addr1.address, nftStakeContract.address], [10, 10], 100000, 1)).to.revertedWith("Cannot reward for self")
        })

        it("Fail if reward is 0", async () => {
            await expect(nftStakeContract.createReward([addr1.address, addr2.address], [10, 0], 100000, 1)).to.revertedWith("Reward cannot be zero")
        })

        it("Fail if not approve enough money", async () => {
            await expect(nftStakeContract.createReward([addr1.address, addr2.address], [10, 10], 100000, 1)).to.revertedWith("ERC20: insufficient allowance")
        })

        it("create reward successfully", async () => {
            await rewardToken.connect(owner).approve(nftStakeContract.address, ethers.utils.parseEther("100000"));
            await nftStakeContract.createReward([addr1.address, addr2.address], [50000, 50000], 100000, 1);
        })
    })

    describe("claim", () => {
        it(" unstake nft and claim token successfully", async () => {
            await nftStakeContract.connect(addr1).claim([0, 1], 1);
            expect(await nftContract.ownerOf(0)).to.equal(addr1.address)
            expect(await nftContract.ownerOf(1)).to.equal(addr1.address)
        })
    })
});
