require('@nomicfoundation/hardhat-toolbox');
require("@nomiclabs/hardhat-ethers");

const dotenv = require('dotenv');
dotenv.config();

module.exports = {
  solidity: '0.8.10',
  networks: {
    hardhat: {},
    ganache: {
      url: "http://127.0.0.1:7545",
      accounts: [
        `0x9f29d5add59c0a34d10509f63d50e34270c605c6913ebdeac2512b62367992fa`,
      ],
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || '',
      accounts: process.env.PRIVATE_KEY_MAINNET
        ? [process.env.PRIVATE_KEY_MAINNET]
        : [],
    },
    kovan: {
      url: process.env.KOVAN_RPC_URL || '',
      accounts: process.env.PRIVATE_KEY_KOVAN
        ? [process.env.PRIVATE_KEY_KOVAN]
        : [],
    },
    goerli: {
      url: process.env.GOERLI_RPC_URL || '',
      accounts: process.env.PRIVATE_KEY_GOERLI
        ? [process.env.PRIVATE_KEY_GOERLI]
        : [],
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL || '',
      accounts: process.env.PRIVATE_KEY_POLYGON
        ? [process.env.PRIVATE_KEY_POLYGON]
        : [],
    },
    mumbai: {
      url: process.env.MUMBAI_RPC_URL || '',
      accounts: process.env.PRIVATE_KEY_MUMBAI
        ? [process.env.PRIVATE_KEY_MUMBAI]
        : [],
    },
    bsctestnet: {
      url: process.env.BSC_RPC_URL || '',
      accounts: process.env.PRIVATE_KEY_BSC
        ? [process.env.PRIVATE_KEY_BSC]
        : [],
      chainId: 97,
      gasPrice: 20000000000,
    },
  },
};
