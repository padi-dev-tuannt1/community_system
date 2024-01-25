const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

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
        prices = [1000, 1010, 1020, 1030, 1040, 1050, 1060, 1070, 1080, 1090, 1100];

        devAddress = "0xe42B1F6BE2DDb834615943F2b41242B172788E7E"
        loyalNFTContract = await loyalFactory.deploy(erc20Token.address, "http://ipfs", devAddress, prices, administrator.address)

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

        it("Drop NFT for team successfully", async () => {
            await administrator.connect(owner).submitTransaction(
                loyalNFTContract.address,
                0,
                loyalNFTContract.interface.encodeFunctionData("dropNFTForTeam")
            )

            await administrator.connect(addr1).confirmTransaction(0)
            await administrator.connect(owner).confirmTransaction(0)

            await administrator.connect(addr1).executeTransaction(0)

            expect((await loyalNFTContract.connect(devAddress).balanceOf(devAddress)).toNumber()).greaterThan(0)
        })

        it("Can't drop NFT if you already drop", async () => {
            await administrator.connect(owner).submitTransaction(
                loyalNFTContract.address,
                0,
                loyalNFTContract.interface.encodeFunctionData("dropNFTForTeam")
            )

            await administrator.connect(addr1).confirmTransaction(1)
            await administrator.connect(owner).confirmTransaction(1)

            await expect(administrator.connect(addr1).executeTransaction(1)).to.be.reverted
        })

    });
});
