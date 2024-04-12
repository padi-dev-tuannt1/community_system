const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Loyal NFT", async () => {
    let owner;
    let addr1;
    let addr2;
    let devAddress;
    let loyalNFTContract;
    let erc20Token;
    let prices;
    let administrator;

    before(async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        erc20Token = await (await ethers.getContractFactory("USDC")).deploy()
        const administratorFactory = await ethers.getContractFactory("Administrators")
        administrator = await administratorFactory.deploy([owner.address, addr1.address, addr2.address], 2);
        const loyalFactory = await ethers.getContractFactory("LoyalNFT");
        prices = [1000, 1010, 1020, 1030, 1040, 1050, 1060, 1070, 1080, 1090, 1100, 1130, 1160, 1190, 1220, 1250, 1280, 1310, 1340, 1370, 1400, 1450, 1500, 1550, 1600, 1650, 1700, 1750, 1800, 1850, 1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800];

        devAddress = "0xe42B1F6BE2DDb834615943F2b41242B172788E7E"
        loyalNFTContract = await upgrades.deployProxy(loyalFactory, [erc20Token.address, "http://ipfs", devAddress, prices, "LoyalNFT", "LNFT", administrator.address], { kind: "uups" })

        erc20Token.connect(addr1).mint(1000000000000000);
    });

    describe("Buy NFT", () => {
        it("Fail because not approve enough money", async () => {
            await expect(loyalNFTContract.connect(addr1).buy(1)).to.revertedWith("ERC20: insufficient allowance")
        });

        it("Buy 1 NFT successfully", async () => {
            const price = await loyalNFTContract.getCurrentPrice();
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther(price.toString()))
            const tx = await loyalNFTContract.connect(addr1).buy(1)
            const receipt = await tx.wait(1);
            expect(await loyalNFTContract.totalSold()).to.equal("1")
            expect(await erc20Token.balanceOf(loyalNFTContract.address)).to.equal(ethers.utils.parseEther(price.toString()))
        });

        it("Buy NFT in different range of price", async () => {
            //buy first 1000 NFT
            let price = await loyalNFTContract.getCurrentPrice();
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther((price * 1000).toString()))
            await loyalNFTContract.connect(addr1).buy(200)
            await loyalNFTContract.connect(addr1).buy(200)
            await loyalNFTContract.connect(addr1).buy(200)
            await loyalNFTContract.connect(addr1).buy(200)
            await loyalNFTContract.connect(addr1).buy(200)
            expect(await loyalNFTContract.totalSold()).to.equal("1001")
            expect(await loyalNFTContract.getCurrentPrice()).to.equal("1000")

            //After totalSold reach 1200 it change the price
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther((price * 199).toString()))
            await loyalNFTContract.connect(addr1).buy(199)
            expect(await loyalNFTContract.totalSold()).to.equal("1200")
            expect(await loyalNFTContract.getCurrentPrice()).to.equal("1010")


            price = await loyalNFTContract.getCurrentPrice();
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther((price * 100).toString()))
            await loyalNFTContract.connect(addr1).buy(100)
            expect(await loyalNFTContract.totalSold()).to.equal("1300")
            expect(await loyalNFTContract.getCurrentPrice()).to.equal("1010")

            //After totalSold reach 1400 it change the price
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther((price * 100).toString()))
            await loyalNFTContract.connect(addr1).buy(100)
            expect(await loyalNFTContract.totalSold()).to.equal("1400")
            expect(await loyalNFTContract.getCurrentPrice()).to.equal("1020")

        })

        it("Create voucher fail if start time is greater than end time", async () => {
            await expect(loyalNFTContract.setVoucher(Math.round((Date.now() + 1000) / 1000), Math.round(Date.now() / 1000), 10)).to.be.revertedWith("Invalid time")
        })

        it("Create voucher fail if percent is invalid", async () => {
            await expect(loyalNFTContract.setVoucher(Math.round(Date.now() / 1000), Math.round((Date.now() + 1000) / 1000), 0)).to.be.revertedWith("Invalid percent")
            await expect(loyalNFTContract.setVoucher(Math.round(Date.now() / 1000), Math.round((Date.now() + 1000) / 1000), 101)).to.be.revertedWith("Invalid percent")
        })

        it("Create voucher successfully", async () => {
            await loyalNFTContract.setVoucher(Math.round(Date.now() / 1000), Math.round((Date.now() + 60 * 1000) / 1000), 10)
        })

        it("Buy with voucher successfully", async () => {
            let price = await loyalNFTContract.getCurrentPrice();
            let voucher = await loyalNFTContract.voucher()
            price = price - voucher.discountPercent;
            const balanceBefore = await erc20Token.balanceOf(addr1.address);
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther((price).toString()))
            await loyalNFTContract.connect(addr1).buy(1)
            const balanceAfter = await erc20Token.balanceOf(addr1.address);
            expect(ethers.utils.formatEther(balanceBefore.sub(balanceAfter))).to.equal("918.0")
        })

        it("If voucher is end, price back to normal", async () => {
            await time.increaseTo(Math.round((Date.now() + 60 * 1000) / 1000));
            let price = await loyalNFTContract.getCurrentPrice();
            const balanceBefore = await erc20Token.balanceOf(addr1.address);
            await erc20Token.connect(addr1).approve(loyalNFTContract.address, ethers.utils.parseEther((price).toString()))
            await loyalNFTContract.connect(addr1).buy(1)
            const balanceAfter = await erc20Token.balanceOf(addr1.address);
            expect(ethers.utils.formatEther(balanceBefore.sub(balanceAfter))).to.equal("1020.0")
        })

        it("Cannot transfer loyal NFT if not in whitelist", async () => {
            await expect(loyalNFTContract.connect(addr1).transferFrom(addr1.address, owner.address, 0)).to.be.revertedWith("Transfer NFT failed")
        })

        it("Can transfer loyal NFT if you in whitelist", async () => {
            await loyalNFTContract.addToWhitelist([addr1.address])
            await loyalNFTContract.connect(addr1).transferFrom(addr1.address, owner.address, 0);

            expect(await loyalNFTContract.ownerOf(0)).to.equal(owner.address)
        })

        it("Drop NFT for team successfully", async () => {
            await loyalNFTContract.connect(owner).dropNFTForTeam()

            expect((await loyalNFTContract.connect(devAddress).balanceOf(devAddress)).toNumber()).greaterThan(0)
        })

        it("Can't drop NFT if you already drop", async () => {
            await expect(loyalNFTContract.connect(owner).dropNFTForTeam()).to.be.reverted
        })

    });
});
