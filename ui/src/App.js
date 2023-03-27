import React, { useState } from "react";
import { ethers } from "ethers";

function App() {
  const [projects, setProjects] = useState([]);
  const [walletAddress, setWalletAddress] = useState("");
  const [provider, setProvider] = useState({});
  const [contract, setContract] = useState({});
  const [signer, setSigner] = useState({});
  const [newProject, setNewProject] = useState({
    title: "",
    description: "",
    fundingGoal: "",
    deadline: "",
  });

  const handleInputChange = (event) => {
    setNewProject({
      ...newProject,
      [event.target.name]: event.target.value,
    });
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    setProjects([...projects, newProject]);
    setNewProject({
      title: "",
      description: "",
      fundingGoal: "",
      deadline: "",
    });
  };

  const initContract = async () => {
    console.log("init contact");
    let tempprovider = new ethers.providers.Web3Provider(window.ethereum);
    setProvider(tempprovider);
    // provider = new ethers.providers.JsonRpcProvider({url:'http://127.0.0.1:8545/'});
    let tempsigner = tempprovider.getSigner();
    console.log(tempsigner);
    setSigner(tempsigner);
    let contractAddress = "0x1330DbB5F0D790e06316A456949535722740c54d";
    let abi = [
      {
        "inputs": [
          {
            "internalType": "string",
            "name": "_name",
            "type": "string"
          },
          {
            "internalType": "uint256",
            "name": "_fundingGoal",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "_totalNFTs",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "_deadline",
            "type": "uint256"
          }
        ],
        "name": "createProject",
        "outputs": [
          {
            "internalType": "uint256",
            "name": "",
            "type": "uint256"
          }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "anonymous": false,
        "inputs": [
          {
            "indexed": true,
            "internalType": "address",
            "name": "investor",
            "type": "address"
          },
          {
            "indexed": true,
            "internalType": "uint256",
            "name": "projectId",
            "type": "uint256"
          },
          {
            "indexed": false,
            "internalType": "uint256",
            "name": "amount",
            "type": "uint256"
          }
        ],
        "name": "InvestmentMade",
        "type": "event"
      },
      {
        "anonymous": false,
        "inputs": [
          {
            "indexed": true,
            "internalType": "address",
            "name": "investor",
            "type": "address"
          },
          {
            "indexed": true,
            "internalType": "uint256",
            "name": "projectId",
            "type": "uint256"
          },
          {
            "indexed": false,
            "internalType": "uint256",
            "name": "profit",
            "type": "uint256"
          }
        ],
        "name": "ProfitClaimed",
        "type": "event"
      },
      {
        "anonymous": false,
        "inputs": [
          {
            "indexed": false,
            "internalType": "uint256",
            "name": "projectId",
            "type": "uint256"
          },
          {
            "indexed": false,
            "internalType": "string",
            "name": "name",
            "type": "string"
          },
          {
            "indexed": false,
            "internalType": "uint256",
            "name": "goal",
            "type": "uint256"
          },
          {
            "indexed": false,
            "internalType": "uint256",
            "name": "deadline",
            "type": "uint256"
          }
        ],
        "name": "ProjectCreated",
        "type": "event"
      },
      {
        "inputs": [],
        "name": "getAllProjects",
        "outputs": [
          {
            "internalType": "string",
            "name": "",
            "type": "string"
          }
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "numberOfProjects",
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
            "name": "",
            "type": "uint256"
          }
        ],
        "name": "projects",
        "outputs": [
          {
            "internalType": "uint256",
            "name": "id",
            "type": "uint256"
          },
          {
            "internalType": "address",
            "name": "ownerAddress",
            "type": "address"
          },
          {
            "internalType": "string",
            "name": "name",
            "type": "string"
          },
          {
            "internalType": "uint256",
            "name": "fundingGoal",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "totalNFTs",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "deadline",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "amountCollected",
            "type": "uint256"
          }
        ],
        "stateMutability": "view",
        "type": "function"
      }
    ];
    let tempcontract = new ethers.Contract(contractAddress, abi, tempsigner);
    setContract(new ethers.Contract(contractAddress, abi, tempcontract));
    console.log(tempcontract);

    // const projectList = await contract.getAllProjects();
    const nop = await contract.numberOfProjects();

    console.log("prokecg ---> ", "asda ", nop, "asd");
  }

  const connectToMM = (event) => {
    initContract();
    projects.push({
      title: "asda",
      description: "asd",
      fundingGoal: "asd",
      deadline: "asd",
    });
    async function getWalletAddress() {
      if (window.ethereum) {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        setWalletAddress(accounts[0]);
      }
    }
    getWalletAddress();
  };

  const ss = (event) => {
    console.log(signer);
  };

  return (
    <div>
      {walletAddress ? (
        <p>Wallet Address: {walletAddress}</p>
      ) : (
        <button onClick={connectToMM}>Connect to Metamask</button>
      )}
        <button onClick={ss}>show signer</button>

      <h1>Create a Project</h1>
      <form onSubmit={handleSubmit}>
        <label>
          Title:
          <input
            type="text"
            name="title"
            value={newProject.title}
            onChange={handleInputChange}
          />
        </label>
        <br />
        <label>
          Description:
          <textarea
            name="description"
            value={newProject.description}
            onChange={handleInputChange}
          />
        </label>
        <br />
        <label>
          Funding Goal:
          <input
            type="number"
            name="fundingGoal"
            value={newProject.fundingGoal}
            onChange={handleInputChange}
          />
        </label>
        <br />
        <label>
          Deadline:
          <input
            type="date"
            name="deadline"
            value={newProject.deadline}
            onChange={handleInputChange}
          />
        </label>
        <br />
        <button type="submit">Create Project</button>
      </form>

      <hr />

      <h1>All Projects</h1>
      {projects.map((project, index) => (
        <div key={index}>
          <h2>{project.title}</h2>
          <p>{project.description}</p>
          <p>Funding Goal: ${project.fundingGoal}</p>
          <p>Deadline: {project.deadline}</p>
        </div>
      ))}
    </div>
  );
}

export default App;