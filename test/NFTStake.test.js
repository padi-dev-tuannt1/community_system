const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("NFT stake", async () => {
    let owner;
    let addr1;
    let addr2;
    let nftStakeContract;
    let nftContract;
    let rewardToken;
    let season;
    let administrator;
    before(async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        rewardToken = await (await ethers.getContractFactory("MEWA")).deploy();
        nftContract = await (await ethers.getContractFactory("SimpleERC721")).deploy();

        const administratorFactory = await ethers.getContractFactory("Administrators")
        administrator = await administratorFactory.deploy([owner.address, addr1.address, addr2.address], 2);


        const nftStakeFactory = await ethers.getContractFactory("NFTStake");
        nftStakeContract = await upgrades.deployProxy(nftStakeFactory, [nftContract.address, rewardToken.address, administrator.address], { kind: "uups" })

        for (i = 0; i < 2; i++) { nftContract.mint(addr1.address) };
        nftContract.mint(owner.address);
        season = 1;

        rewardToken.mint(100000);
    });

    describe("Stake NFT", () => {

        it("Fail if you are not owner of NFT", async () => {
            await nftContract.connect(addr1).approve(nftStakeContract.address, 0);
            await expect(nftStakeContract.connect(owner).stake(0, season)).to.revertedWith("NotItemOwner");
        });

        it("Stake NFT successfully", async () => {
            await nftStakeContract.connect(addr1).stake(0, season);
            expect(await nftStakeContract.stakeInfos(0)).to.have.property('owner', addr1.address)
            expect(await nftStakeContract.stakeInfos(0)).to.have.property('status', 1)

            await nftContract.connect(addr1).approve(nftStakeContract.address, 1);
            await nftStakeContract.connect(addr1).stake(1, season);
            expect(await nftStakeContract.stakeInfos(1)).to.have.property('owner', addr1.address)
            expect(await nftStakeContract.stakeInfos(1)).to.have.property('status', 1)

        })

        it("Fail if NFT is already stake", async () => {
            await expect(nftStakeContract.connect(addr1).stake(0, season)).to.revertedWith("Already stake")
        })
    });

    describe("create reward", () => {
        it("Set the reward successfully", async () => {

            tx = await administrator
                .connect(owner)
                .submitTransaction(
                    nftStakeContract.address,
                    0,
                    nftStakeContract.interface.encodeFunctionData("createReward", [
                        [addr1.address, addr2.address], [50000, 50000], 100000, 1
                    ])
                );
            await tx.wait(0);

            tx = await administrator.connect(addr1).confirmTransaction(0);
            await tx.wait(0);

            tx = await administrator.connect(owner).confirmTransaction(0);
            await tx.wait(0);

            tx = await administrator.connect(owner).executeTransaction(0);
            await tx.wait(0);
        })

    })

    describe("claim", () => {
        before(async () => {
            rewardToken.connect(owner).transfer(nftStakeContract.address, ethers.utils.parseEther("100000"))
        })
        it(" unstake nft and claim token successfully", async () => {
            await nftStakeContract.connect(addr1).claim([0, 1], 1);
            expect(await nftContract.ownerOf(0)).to.equal(addr1.address)
            expect(await nftContract.ownerOf(1)).to.equal(addr1.address)

            // //other address claim success
            // await nftStakeContract.connect(addr2).claim([0, 1], 1);
            // expect(await nftContract.ownerOf(0)).to.equal(addr1.address)
            // expect(await nftContract.ownerOf(1)).to.equal(addr1.address)
        })
    })
});
