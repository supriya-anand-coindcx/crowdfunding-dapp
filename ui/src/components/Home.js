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
    const [contract, setContract] = useState({});
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
        let tempprovider = new ethers.providers.Web3Provider(window.ethereum);
        setProvider(tempprovider);
        let tempsigner = tempprovider.getSigner();
        setSigner(tempsigner);
        let contractAddress = "0x1330DbB5F0D790e06316A456949535722740c54d";
        let abi = Constants.ABI_SMART_CONTRACT;
        let tempcontract = new ethers.Contract(contractAddress, abi, tempsigner);
        setContract(tempcontract);
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
        let nop = await contract.numberOfProjects();
        const pp = [];
        for (let i = 0; i < nop; i++) {
            const p = await contract.projects(i);
            const newproject = {
                name: p.name,
                fundingGoal: BigNumber(p['fundingGoal']._hex).toString(),
                deadline: BigNumber(p['deadline']._hex).toString(),
            };
            pp.push(newproject);
        };
        setProjects([...projects, ...pp]);
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
        const p = await contract.createProject(newProject.name, newProject.fundingGoal, 1, deadline);
        console.log(p);
    };

    const contributeToProject = async (event) => {

    };

    return (
        <div>
            {walletAddress ? (
                <p>Wallet Address: {walletAddress}</p>
            ) : (
                <button onClick={connectToMM}>Connect to Metamask</button>
            )}
            <button onClick={ss}>show signer</button>

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