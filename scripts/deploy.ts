import { ethers, upgrades } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log('Deploying contracts with the account:', deployer.address);

    const fundMeToken = await ethers.deployContract("FundMeToken", [ethers.parseEther("100000")]);

    await fundMeToken.waitForDeployment();

    const fundMeFaucet = await ethers.deployContract("FundMeFaucet", [fundMeToken]);
    await fundMeFaucet.waitForDeployment();

    const UUPSProxy = await ethers.deployContract("UUPSProxy");
    await UUPSProxy.waitForDeployment();

    const maxDuration = 1000000000000000;

    const CrowdFundingPlatform = await ethers.getContractFactory("CrowdFundingPlatform");
    const crowdFundingPlatform = await upgrades.deployProxy(CrowdFundingPlatform, [maxDuration, await fundMeToken.getAddress()]);
    crowdFundingPlatform.waitForDeployment();

    console.log('FundMeToken deployed to:', await fundMeToken.getAddress());
    console.log('FundMeFaucet deployed to:', await fundMeFaucet.getAddress());
    console.log("UUPSProxy deployed to:", await UUPSProxy.getAddress());
    console.log("CrowdFundingPlatform deployed to:", await crowdFundingPlatform.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
