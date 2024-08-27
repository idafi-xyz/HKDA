import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";

dotenv.config();
const config: HardhatUserConfig = {
  solidity: {
    version:"0.8.26",
    settings:{
      optimizer:{
        enabled: true,
        runs:200
      }
    }
  },
  defaultNetwork:"hardhat",
  networks:{
    hardhat: {},
    testnet: {
      url: process.env.TESTNET_URL,
      accounts:[process.env.TESTNET_SIGNER_KEY||""]
    },
    polygonAmoy:{
      url:process.env.POLYGONAMOY_URL,
      accounts:[process.env.POLYGONAMOY_SIGNER_KEY||""]
    },
    sepolia:{
      url:process.env.SEPOLIA_URL,
      accounts:[process.env.SEPOLIA_SIGNER_KEY||""]
    }
  }
};

export default config;
