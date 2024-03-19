const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("Administrators", () => {
    let deployer;
    // Administrators
    let alice;
    let bob;
    let david;
    let addrs;
    // Contracts
    let administratorContract;
    let erc20Contract;
    let tx;

    before(async () => {
        [deployer, alice, bob, david, ...addrs] = await ethers.getSigners();

        let administratorFactory = await ethers.getContractFactory(
            "Administrators"
        );
        administratorContract = await administratorFactory.deploy(
            [alice.address, bob.address, david.address],
            2
        );
        const ERC20TokenFactory = await ethers.getContractFactory("MEWA");
        erc20Contract = await ERC20TokenFactory.deploy()

        erc20Contract.transfer(administratorContract.address, ethers.utils.parseEther("10000"))

    });
    describe("Alice request for grant role and to be accepted", () => {

        before(async () => {

            tx = await administratorContract
                .connect(alice)
                .submitTransaction(
                    erc20Contract.address,
                    0,
                    erc20Contract.interface.encodeFunctionData("transfer", [
                        david.address,
                        ethers.utils.parseEther("100"),
                    ])
                );
            await tx.wait(0);

            tx = await administratorContract.connect(alice).confirmTransaction(0);
            await tx.wait(0);
        });

        it("Check first transaction exist with numConfirmations equal 1", async () => {
            const data = await administratorContract.transactions(0);
            expect(data.numConfirmations).to.be.eq(1);
            expect(data).not.null;
        });

        it("Intital, david balance equal 0", async () => {
            expect(
                await erc20Contract.balanceOf(david.address)
            ).to.be.eq(0);
        });

        describe("Bob accept transaction", () => {
            before(async () => {
                tx = await administratorContract.connect(bob).confirmTransaction(0);
                await tx.wait(0);
            });

            it("Check first transaction data have increase numConfirmations", async () => {
                const data = await administratorContract.transactions(0);
                expect(data.numConfirmations).to.be.eq(2);
                expect(data).not.null;
            });
        });

        describe("After bob accept transaction, do execute", () => {
            before(async () => {
                tx = await administratorContract.connect(alice).executeTransaction(0);
                await tx.wait(0);
            });

            it("Check balance of david increase to 100", async () => {
                expect(
                    await erc20Contract.balanceOf(david.address)
                ).to.be.eq(ethers.utils.parseEther("100"));
            });

            it("Check transaction have been in executed state", async () => {
                const data = await administratorContract.transactions(0);
                expect(data.executed).to.be.eq(true);
                expect(data).not.null;
            });
        });
    })


});
