const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("CP Token", async () => {
    let owner;
    let addr1;
    let addr2;
    let loyalNFTContract;
    let erc20Token;


    before(async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        erc20Token = await (await ethers.getContractFactory("CPToken")).deploy()
        const loyalFactory = await ethers.getContractFactory("LoyalNFT");
        loyalNFTContract = await loyalFactory.deploy(erc20Token.address, "http://ipfs")

        erc20Token.connect(addr1).mint(10000000);
    });

    describe("Buy NFT", () => {
        it("Fail because not approve enough money", async () => {
            await expect(loyalNFTContract.connect(addr1).buy()).to.revertedWith("ERC20: insufficient allowance")
        });

        it("Buy 1 NFT successfully", async () => {
            const price = await loyalNFTContract.getCurrentPrice();
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther(price.toString()))
            await loyalNFTContract.connect(addr1).buy()
            expect(await loyalNFTContract.totalSold()).to.equal("1")
            expect(await loyalNFTContract.totalSoldPublic()).to.equal("0")
            expect(await erc20Token.balanceOf(loyalNFTContract.address)).to.equal(ethers.utils.parseEther(price.toString()))
        });

        it("Buy all private NFTs", async () => {
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther("10000000"))
            for (i = 1; i < 1400; i++) {
                await loyalNFTContract.connect(addr1).buy()
            }
        });

        it("Price change when buy 40 NFT in public sale", async () => {
            for (i = 1; i <= 40; i++) {
                await loyalNFTContract.connect(addr1).buy()
            }
            expect((await loyalNFTContract.getCurrentPrice()).toString()).to.equal("1020")
            expect((await loyalNFTContract.totalSupply()).toString()).to.equal("1440")
        });

        it("Drop NFT for team successfully", async () => {
            await loyalNFTContract.dropNFTForTeam()
            expect((await loyalNFTContract.totalSupply()).toString()).to.equal("1560")
        })

        it("Can't drop NFT if you already drop", async () => {
            await expect(loyalNFTContract.dropNFTForTeam()).to.be.reverted
        })

        it("Can Drop NFT again when user buy enough NFT", async () => {
            for (i = 1; i <= 400; i++) {
                await loyalNFTContract.connect(addr1).buy()
            }
            await loyalNFTContract.dropNFTForTeam()
            console.log((await loyalNFTContract.totalSupply()).toString())
        })
    });
});
