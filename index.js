import { ethers } from "ethers";

//no url is provided - connects to localhost:8545
const provider = new ethers.providers.JsonRpcProvider({url:'http://127.0.0.1:8545/'});

// const providerInfura = new ethers.providers.InfuraProvider("goerli", "62c36671929247c28067de709013b0ef");
const adminWallet = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);

const add = await adminWallet.getAddress();

console.log(add);

