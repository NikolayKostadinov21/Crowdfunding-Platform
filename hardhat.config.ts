import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades"

const config: HardhatUserConfig = {
    solidity: "0.8.20",
    // etherscan: {
    //     apiKey: "<ETHERSCAN-API-KEY>",
    // },
    // networks: {
    //     Sepolia: {
    //         url: "https://sepolia.infura.io/v3/<INFURA-API-KEY>",
    //         accounts: ["YOUR_PRIVATE_KEY"]
    //     }
    // }
};

export default config;
