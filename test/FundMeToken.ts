import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("FundMeToken", function () {

    async function deployFundMeToken() {
        const initialSupply = 10000;
        const FundMeToken = await ethers.getContractFactory("FundMeToken");

        const fundMeToken = await FundMeToken.deploy(initialSupply);

        return { fundMeToken };
    }

    it('Should have correct name and symbol', async () => {
        const { fundMeToken } = await loadFixture(deployFundMeToken);
        expect(await fundMeToken.name()).to.equal('FundMe Token');
        expect(await fundMeToken.symbol()).to.equal('FMT');
    });

    it('Should assign initial supply to sender', async () => {
        const { fundMeToken } = await loadFixture(deployFundMeToken);
        const [sender] = await ethers.getSigners();
        const balance = await fundMeToken.balanceOf(sender.address);
        expect(balance).to.equal(ethers.parseEther('0.00000000000001'));
    });
});