import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log('Deploying contracts with the account:', deployer.address);

    const initialSupply = 100000000;

    const fundMeToken = await ethers.deployContract("FundMeToken", [deployer.address, initialSupply]);

    await fundMeToken.waitForDeployment();
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
