import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import "dotenv/config";

const privateKey = process.env.DEV1_PRIVATE_KEY;
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.14",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.4.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    matic: {
      url: `https://polished-polished-sky.matic.quiknode.pro/89584db94423d9ece9752c758bfd55f1b07bb7bf/`,
      accounts: [privateKey!],
      forking: {
        url: `https://polished-polished-sky.matic.quiknode.pro/89584db94423d9ece9752c758bfd55f1b07bb7bf/`,
        blockNumber: 38019624,
      },
    },
  },
  etherscan: {
    apiKey: {
      polygon: "5BYDKGPGNTPXT2BEKUYZMG5GCMIC86RUW2",
    },
  },
};

export default config;
