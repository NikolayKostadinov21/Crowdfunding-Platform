import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("UUPSProxy", function () {

    async function deployUUPSProxy() {
        const [owner] = await ethers.getSigners();
        const _UUPSProxy = await ethers.getContractFactory("UUPSProxy");

        const UUPSProxy = await _UUPSProxy.deploy();

        return { UUPSProxy, owner };
    }
    it("should initialize the proxy with the initial logic contract", async () => {
        const { UUPSProxy, owner } = await loadFixture(deployUUPSProxy);
        // Deploy a sample implementation contract for testing
        const ImplementationContract = await ethers.getContractFactory("CrowdFundingPlatform");
        const implementationContract = await ImplementationContract.deploy();

        // Initialize the proxy with the implementation contract
        await UUPSProxy.connect(owner).initializeProxy(implementationContract.getAddress());

        // Get the current implementation address
        const currentImplementation = await ethers.provider.getStorage(await UUPSProxy.getAddress(), "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc");
        expect(currentImplementation).to.equal((await implementationContract.getAddress()));
    });

    it("should not allow initialization if the initial logic contract is a zero address", async () => {
        const { UUPSProxy, owner } = await loadFixture(deployUUPSProxy);
        // Try to initialize the proxy with a zero address
        await expect(UUPSProxy.connect(owner).initializeProxy("0x0000000000000000000000000000000000000000")).to.be.revertedWithCustomError(UUPSProxy,
            "UUPSPROXY_ZERO_ADDRESS"
        );
    });

    it("should not allow re-initialization of the proxy", async () => {
        const { UUPSProxy, owner } = await loadFixture(deployUUPSProxy);
        // Deploy another sample implementation contract for testing
        const AnotherImplementationContract = await ethers.getContractFactory("FundMeToken");
        const anotherImplementationContract = await AnotherImplementationContract.deploy(1);

        await UUPSProxy.connect(owner).initializeProxy(anotherImplementationContract.getAddress());

        // Try to re-initialize the proxy with a different implementation contract
        await expect(UUPSProxy.connect(owner).initializeProxy("0x0000000000000000000000000000000000000002")).to.be.revertedWithCustomError(UUPSProxy,
            "UUPSPROXY_ALREADY_INITIALIZED"
        );
    });
});