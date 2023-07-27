import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("FundMeFaucet", function () {
    async function deployFundMeFaucet() {
        const initialSupply = 10000;
        const [owner, otherAccount] = await ethers.getSigners();
        const FundMeToken = await ethers.getContractFactory("FundMeToken");
        const fundMeToken = await FundMeToken.deploy(initialSupply);

        const FundMeFaucet = await ethers.getContractFactory("FundMeFaucet");
        const fundMeFaucet = await FundMeFaucet.deploy(fundMeToken.getAddress())

        return { fundMeFaucet, fundMeToken, owner, otherAccount };
    }

    it("should deposit funds and get the balance correctly", async () => {
        const { fundMeFaucet, otherAccount } = await loadFixture(deployFundMeFaucet);
        const depositAmount = ethers.parseEther("0.1");

        // Deposit funds to the faucet contract
        await fundMeFaucet.connect(otherAccount).depositFunds({ value: depositAmount });

        // Check the balance of the contract
        const contractBalance = await fundMeFaucet.getBalance();
        expect(contractBalance).to.equal(depositAmount);
    });

    it("should allow withdrawal of FundMe tokens after 1 minute lock time", async () => {
        const { fundMeFaucet, otherAccount } = await loadFixture(deployFundMeFaucet);
        const withdrawalAmount = ethers.parseEther("0.01");

        // Request tokens from the faucet contract
        await fundMeFaucet.connect(otherAccount).requestTokens();

        // Check the balance of the contract after withdrawal
        const contractBalanceAfterWithdrawal = await fundMeFaucet.getBalance();
        expect(contractBalanceAfterWithdrawal).to.equal(withdrawalAmount);

        // Attempt to request tokens again should fail due to the lock time
        await expect(fundMeFaucet.connect(otherAccount).requestTokens()).to.be.revertedWithCustomError(fundMeFaucet, 
            "INSUFFICIENT_TIME_ELAPSED_SINCE_LAST_WITHDRAWAL"
        );

        // Fast-forward 2 minutes
        await ethers.provider.send("evm_increaseTime", [120]);

        // Request tokens again after lock time has passed
        await fundMeFaucet.connect(otherAccount).requestTokens();

        // Check the balance of the contract after the second withdrawal
        const contractBalanceAfterSecondWithdrawal = await fundMeFaucet.getBalance();
        expect(contractBalanceAfterSecondWithdrawal).to.equal(withdrawalAmount);
    });

    it("should reject requests if the user has insufficient exchanged funds or balance in the contract", async () => {
        const { fundMeFaucet, otherAccount } = await loadFixture(deployFundMeFaucet);
        const withdrawalAmount = ethers.parseEther("0.01");

        // Ensure the user has no exchanged funds and request tokens
        await expect(fundMeFaucet.connect(otherAccount).requestTokens()).to.be.revertedWithCustomError(fundMeFaucet,
            "INSUFFICIENT_EXCHANGED_FUNDS_FOR_FUNDME_TOKEN"
        );

        const depositFunds = ethers.parseEther("0.1");
        // Deposit funds to the faucet contract
        await fundMeFaucet.connect(otherAccount).depositFunds({ value: withdrawalAmount });
            console.log(await fundMeFaucet.getBalance())
        // Request tokens with insufficient exchanged funds should fail
        await expect(fundMeFaucet.connect(otherAccount).requestTokens()).to.be.revertedWithCustomError(fundMeFaucet,
            "INSUFFICIENT_EXCHANGED_FUNDS_FOR_FUNDME_TOKEN"
        );

        // Fast-forward 2 minutes
        await ethers.provider.send("evm_increaseTime", [120]);

        // Request tokens with sufficient exchanged funds but insufficient balance in the contract should fail
        await expect(fundMeFaucet.connect(otherAccount).requestTokens()).to.be.revertedWithCustomError(fundMeFaucet,
            "INSUFFICIENT_BALANCE_IN_FAUCET_FOR_WITHDRAWAL_REQUEST"
        );
    });
});
