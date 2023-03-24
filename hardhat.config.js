require('@nomicfoundation/hardhat-toolbox');

require('@nomiclabs/hardhat-waffle');
const dotenv = require('dotenv');
dotenv.config();

module.exports = {
  solidity: '0.8.10',
  networks: {
    hardhat: {},
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
