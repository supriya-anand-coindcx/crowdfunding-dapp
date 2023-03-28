import React, { useState } from "react";
import { ethers } from "ethers";
import BigNumber from "bignumber.js";
import * as Constants from "../constants/index";

export const Home = () => {
    const [projects, setProjects] = useState([]);
    const [contributeToProjectObj, setContributeToProjectObj] = useState({
        id:"",
        amount: ""
    });
    const [walletAddress, setWalletAddress] = useState("");
    const [provider, setProvider] = useState({});
    const [contractERC20, setContractERC20] = useState({});
    const [contractERC1155, setContractERC1155] = useState({});
    const [signer, setSigner] = useState({});
    const [newProject, setNewProject] = useState({
        name: "",
        fundingGoal: "",
        deadline: "",
    });


    const handleInputChange = (event) => {
        setNewProject({
            ...newProject,
            [event.target.name]: event.target.value,
        });
    };

    const handleInputChangeOfContribute = (event) => {
        setContributeToProjectObj({
            ...contributeToProjectObj,
            [event.target.name]: event.target.value,
        })
    };

    const initContract = async () => {
        console.log("init contact");
        // let tempprovider = new ethers.providers.Web3Provider(window.ethereum);
        let tempprovider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545/");
        setProvider(tempprovider);
        let tempsigner = tempprovider.getSigner();
        setSigner(tempsigner);
        let contractAddressERC20 = process.env.REACT_APP_ERC20_ADDRESS;
        let contractAddressERC1155 = process.env.REACT_APP_ERC1155_ADDRESS;
        let abi_erc20 = Constants.ABI_ERC20;
        let abi_erc1155 = Constants.ABI_ERC1155;
        let tempcontractERC20 = new ethers.Contract(contractAddressERC20, abi_erc20, tempsigner);
        let tempcontractERC1155 = new ethers.Contract(contractAddressERC1155, abi_erc1155, tempsigner);
        setContractERC20(tempcontractERC20);
        setContractERC1155(tempcontractERC1155);
    }

    const connectToMM = (event) => {
        initContract();
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

    const ss = async (event) => {
        console.log(contractERC1155);
        let nop = await contractERC1155.projectId();
        const pp = [];
        for (let i = 0; i < nop; i++) {
            const p = await contractERC1155.projects(i);
            const newproject = {
                name: p.name,
                fundingGoal: BigNumber(p['fundingGoal']._hex).toString(),
                deadline: BigNumber(p['deadline']._hex).toString(),
            };
            pp.push(newproject);
        };
        setProjects([...projects, ...pp]);
        console.log(projects);
    };

    const createProject = async (event) => {
        event.preventDefault();
        setProjects([...projects, newProject]);
        setNewProject({
            name: "",
            fundingGoal: "",
            deadline: "",
        });
        let deadline = new Date(newProject.deadline);
        deadline = Math.floor(deadline.getTime() / 1000);
        const p = await contractERC1155.createProject(newProject.name,ethers.utils.parseEther(newProject.fundingGoal), deadline);
        console.log(p);
    };

    const contributeToProject = async (event) => {
        event.preventDefault();
        setContributeToProjectObj(contributeToProjectObj);
        setContributeToProjectObj({
            id: "",
            amount: "",
        });
        const p = await contractERC1155.contribute(contributeToProjectObj.id, ethers.utils.parseEther(contributeToProjectObj.amount));
        console.log(p);
    };

    const aprroveMoney = async (event) => {
        const p = await contractERC20.approve(process.env.REACT_APP_ERC1155_ADDRESS, 1000000000);
        console.log(p);
    }

    return (
        <div>
            {walletAddress ? (
                <p>Wallet Address: {walletAddress}</p>
            ) : (
                <button onClick={connectToMM}>Connect to Metamask</button>
            )}
            <button onClick={ss}>show signer</button>
            <button onClick={aprroveMoney}>approve money</button>

            <table>
                <td>
                    <h1>Contribute to project: </h1>
                    <form onSubmit={contributeToProject}>
                        <label>
                            id:
                            <input
                                type="number"
                                name="id"
                                value={contributeToProjectObj.id}
                                onChange={handleInputChangeOfContribute}
                            />
                        </label>
                        <br/>
                        <label>
                            Amount To Invest:
                            <input
                                type="number"
                                name="amount"
                                value={contributeToProjectObj.amount}
                                onChange={handleInputChangeOfContribute}
                            />
                        </label>
                        <br/>
                        <button type="submit">Contribute to project</button>
                    </form>
                </td>
                <td>
                    <h1>Create a Project</h1>
                    <form onSubmit={createProject}>
                        <label>
                            Name:
                            <input
                                type="text"
                                name="name"
                                value={newProject.name}
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
                    </td>
            </table>
            <hr />
            <h1>All Projects</h1>
            {projects.map((project, index) => (
                <div key={index}>
                    <h2>Name: {project.name}</h2>
                    <p>Funding Goal: ${project.fundingGoal}</p>
                    <p>Deadline: {project.deadline}</p>
                </div>
            ))}
        </div>
    );
}