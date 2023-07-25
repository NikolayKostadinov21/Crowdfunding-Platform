import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("FundMeToken", function () {

    async function deployFundMeFaucet() {
        const initialSupply = 10000;
        const [owner] = await ethers.getSigners();
        const FundMeToken = await ethers.getContractFactory("FundMeToken");

        const fundMeToken = await FundMeToken.deploy(owner, initialSupply);

        return { fundMeToken };
    }

    it('Should have correct name and symbol', async () => {
        const { fundMeToken } = await loadFixture(deployFundMeFaucet);
        expect(await fundMeToken.name()).to.equal('FundMe Token');
        expect(await fundMeToken.symbol()).to.equal('FMT');
    });

    it('Should assign initial supply to faucet address', async () => {
        const { fundMeToken } = await loadFixture(deployFundMeFaucet);
        const [faucet] = await ethers.getSigners();
        const balance = await fundMeToken.balanceOf(faucet.address);
        expect(balance).to.equal(ethers.parseEther('0.00000000000001'));
    });
});