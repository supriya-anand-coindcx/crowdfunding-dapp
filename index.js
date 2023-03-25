const ethers = require("ethers");

//no url is provided - connects to localhost:8545
const provider = new ethers.providers.JsonRpcProvider({url:'http://127.0.0.1:8545/'});

// const providerInfura = new ethers.providers.InfuraProvider("goerli", "62c36671929247c28067de709013b0ef");
const adminWallet = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);

let abi = [
    {
      "inputs": [],
      "name": "retrieve",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "num",
          "type": "uint256"
        }
      ],
      "name": "store",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
];

const contract = new ethers.Contract("0x5FbDB2315678afecb367f032d93F642f64180aa3" , abi , adminWallet );

async function main(){
    const add = await adminWallet.getAddress();
    console.log(add);
}

async function storeNumber(num){
    const tx = await contract.store(num);
    console.log(tx);
}


async function getNumber(){
    const num = await contract.retrieve();
    console.log("retrieved num: ->", num);
}

main();
storeNumber(1231);
getNumber();

