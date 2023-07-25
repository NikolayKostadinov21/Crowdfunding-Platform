import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("FundMeFaucet", function () {
    async function deployFundMeFaucet() {
        const initialSupply = 10000;
        const [owner, otherAccount] = await ethers.getSigners();
        const FundMeToken = await ethers.getContractFactory("FundMeToken");
        const fundMeToken = await FundMeToken.deploy(owner, initialSupply);

        const FundMeFaucet = await ethers.getContractFactory("FundMeFaucet");
        const fundMeFaucet = await FundMeFaucet.deploy(fundMeToken.getAddress())

        return { fundMeFaucet, fundMeToken, owner, otherAccount };
    }

    it("should deposit funds correctly", async () => {
        const { fundMeFaucet, otherAccount } = await loadFixture(deployFundMeFaucet);
        const depositAmount = ethers.parseEther("1");

        await fundMeFaucet.connect(otherAccount).depositFunds({ value: depositAmount });
        const exchangedFunds = await fundMeFaucet.exchangedFunds(otherAccount.address);
        expect(exchangedFunds).to.equal(depositAmount);
    });

    it("should not deposit zero funds", async () => {
        const { fundMeFaucet, otherAccount } = await loadFixture(deployFundMeFaucet);

        await expect(fundMeFaucet.connect(otherAccount).depositFunds({ value: 0 })).to.be.revertedWith("Exchanging value cannot be equal to zero!");
    });

    it("should request tokens correctly", async () => {
        const withdrawalAmount = ethers.parseEther("0.1");
        const { fundMeFaucet, fundMeToken, otherAccount } = await loadFixture(deployFundMeFaucet);

        // Deposit funds to the contract
        const depositAmount = ethers.parseEther("1");
        await fundMeFaucet.connect(otherAccount).depositFunds({ value: depositAmount });
    
        // Fast-forward 2 minutes
        await ethers.provider.send("evm_increaseTime", [120]);
    
        // Ensure FundMeFaucet contract has the correct token balance before the request
        const faucetBalanceBefore = await fundMeToken.balanceOf(fundMeFaucet);
        expect(faucetBalanceBefore).to.equal(0);
    
        // Get addr1's balance before the request
        const addr1BalanceBefore = await fundMeToken.balanceOf(otherAccount);
    
        // Request tokens
        await fundMeFaucet.connect(otherAccount).requestTokens();
    
        // Ensure FundMeFaucet contract receives the tokens from the owner's account
        const faucetBalanceAfter = await fundMeToken.balanceOf(fundMeFaucet);
        expect(faucetBalanceAfter).to.equal(withdrawalAmount);
    
        // Get addr1's balance after the request
        const addr1BalanceAfter = await fundMeToken.balanceOf(otherAccount);
    
        // Ensure addr1's balance increased by exactly withdrawalAmount
        const tokensReceived = addr1BalanceAfter - addr1BalanceBefore;
        expect(tokensReceived).to.equal(withdrawalAmount);
    
        // Ensure exchangedFunds mapping is updated correctly
        const exchangedFunds = await fundMeFaucet.exchangedFunds(otherAccount);
        expect(exchangedFunds).to.equal(depositAmount);

      });

    it("should not request tokens before 1 minute has passed", async () => {
        const { fundMeFaucet, otherAccount } = await loadFixture(deployFundMeFaucet);
        const depositAmount = ethers.parseEther("1");
        await fundMeFaucet.connect(otherAccount).depositFunds({ value: depositAmount });

        // Try to request tokens immediately
        await expect(fundMeFaucet.connect(otherAccount).requestTokens()).to.be.revertedWith("Insufficient balance in faucet for withdrawal request!");
    });

    it("should not request tokens with insufficient balance in the faucet", async () => {
        const { fundMeFaucet, otherAccount } = await loadFixture(deployFundMeFaucet);
        const depositAmount = ethers.parseEther("0.05");
        await fundMeFaucet.connect(otherAccount).depositFunds({ value: depositAmount });

        // Fast-forward 2 minutes
        await ethers.provider.send("evm_increaseTime", [120]);

        // Try to request tokens with insufficient balance in the faucet
        await expect(fundMeFaucet.connect(otherAccount).requestTokens()).to.be.revertedWith("Insufficient balance in faucet for withdrawal request!");
    });

    it("should not request tokens with insufficient exchanged funds", async () => {
        const { fundMeFaucet, otherAccount } = await loadFixture(deployFundMeFaucet);
        const depositAmount = ethers.parseEther("0.1");
        await fundMeFaucet.connect(otherAccount).depositFunds({ value: depositAmount });

        // Fast-forward 2 minutes
        await ethers.provider.send("evm_increaseTime", [120]);

        // Try to request tokens with insufficient exchanged funds
        await expect(fundMeFaucet.connect(otherAccount).requestTokens()).to.be.revertedWith("Insufficient balance in faucet for withdrawal request!");
    });
});
