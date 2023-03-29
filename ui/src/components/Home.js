import React, { useState, useEffect } from "react";
import { ethers } from "ethers";
import BigNumber from "bignumber.js";
import * as Constants from "../constants/index";

export const Home = () => {
    const [projects, setProjects] = useState([]);
    const [investment, setInvestment] = useState([]);
    const [contributeToProjectObj, setContributeToProjectObj] = useState({
        id:"",
        amount: ""
    });
    const [balance, setBalance] = useState("");
    const [walletAddress, setWalletAddress] = useState("");
    const [adminWallet, setAdminWallet] = useState("");
    const [provider, setProvider] = useState({});
    const [adminProvider, setAdminProvider] = useState("");
    const [contractERC20, setContractERC20] = useState({});
    const [contractERC1155, setContractERC1155] = useState({});
    const [signer, setSigner] = useState({});
    const [adminSigner, setAdminSigner] = useState("");
    const [newProject, setNewProject] = useState({
        name: "",
        fundingGoal: "",
        deadline: "",
    });
    const [ccheckallowance, setCcheckAllowance] = useState("");

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
        let tempproviderUser = new ethers.providers.Web3Provider(window.ethereum);
        let tempproviderAdmin = new ethers.providers.JsonRpcProvider("http://127.0.0.1:7545/");
        let aw = new ethers.Wallet(process.env.REACT_APP_DEPLOYMENT_ADDRESS_PRIVATE_KEY, tempproviderAdmin);
        setAdminWallet(aw);
        setProvider(tempproviderUser);
        setAdminProvider(tempproviderAdmin);
        let tempsignerUser = tempproviderUser.getSigner();
        let tempsignerAdmin = tempproviderAdmin.getSigner();
        setSigner(tempsignerUser);
        setAdminSigner(tempsignerAdmin);
        let contractAddressERC20 = process.env.REACT_APP_ERC20_ADDRESS;
        let contractAddressERC1155 = process.env.REACT_APP_ERC1155_ADDRESS;
        let abi_erc20 = Constants.ABI_ERC20;
        let abi_erc1155 = Constants.ABI_ERC1155;
        let tempcontractERC20User = new ethers.Contract(contractAddressERC20, abi_erc20, tempsignerUser);
        let tempcontractERC1155User = new ethers.Contract(contractAddressERC1155, abi_erc1155, tempsignerUser);
        setContractERC20(tempcontractERC20User);
        setContractERC1155(tempcontractERC1155User);
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
        // GET PROJECTS and INVESTMENTS
        setProjects([]);
        let nop = await contractERC1155.projectId();
        const pp = [];
        const inv = [];
        for (let i = 0; i < nop; i++) {
            const p = await contractERC1155.projects(i);
            const newproject = {
                id: BigNumber(p['id']._hex).toString(),
                name: p.name,
                fundingGoal: BigNumber(p['fundingGoal']._hex).toString(),
                deadline: BigNumber(p['deadline']._hex).toString(),
            };
            pp.push(newproject);

            const invv = await contractERC1155.getInvestment(i);
            // console.log(p, " -> " , invv);
            const newinv = {
                amount: BigNumber(invv['0']._hex).toString(),
                claimed: invv['2'].toString(),
                active: invv['3'].toString()
            }
            inv.push(newinv);
        };
        await setProjects([...pp]);
        await setInvestment(inv);
    };

    useEffect(() => {
        setInvestment(investment);
        setProjects(projects);
    }, [investment, projects]);

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
        const p = await contractERC1155.createProject(newProject.name,newProject.fundingGoal, deadline);
        console.log("create project : ", p);
    };

    const contributeToProject = async (event) => {
        event.preventDefault();
        setContributeToProjectObj(contributeToProjectObj);
        setContributeToProjectObj({
            id: "",
            amount: "",
        });
        const p = await contractERC1155.contribute(contributeToProjectObj.id, contributeToProjectObj.amount);
        console.log("contribute to project : ",p);
    };

    const aprroveMoney = async (event) => {
        event.preventDefault();
        if(event.target[1].value){
            const p = await contractERC20.connect(signer).approve(event.target[1].value, event.target[0].value);
            console.log("approve money : ", p, " ", BigNumber(p._hex).toString());
        } else {
            const p = await contractERC20.connect(signer).approve(process.env.REACT_APP_ERC1155_ADDRESS, event.target[0].value);
            console.log("approve money : ", p, " ", BigNumber(p._hex).toString());
        }
    }

    const transfererc20 = async (event) => {
        event.preventDefault();
        const p = await contractERC20.connect(adminWallet).transfer(event.target[0].value, event.target[1].value);
        console.log("transfer erc20 : ", p);
    }

    const checkallowance = async (event) => {
        const p = await contractERC20.connect(walletAddress).allowance(walletAddress, process.env.REACT_APP_ERC1155_ADDRESS);
        console.log("check allowance : ", p, " ", BigNumber(p._hex).toString());
        setCcheckAllowance(BigNumber(p._hex).toString());
    }

    const showbalance = async (event) => {
        const p2 = await contractERC20.balanceOf(walletAddress);
        setBalance(BigNumber(p2._hex).toString());
        console.log("show balance : ", BigNumber(p2._hex).toString());
    }

    const claim = async (event) => {
        event.preventDefault();
        const p = await contractERC1155.claim(event.target[0].value);
        console.log("claim : ", p);
    }

    const changeDeadline = async (event) => {
        event.preventDefault();
        let deadline = new Date(event.target[1].value);
        deadline = Math.floor(deadline.getTime() / 1000);
        const cd = await contractERC1155.changeDeadline(event.target[0].value, deadline);
        console.log("change deadline : ", cd);
    };

    return (
        <div>
            <div><button onClick={connectToMM}>Connect to Metamas : <p>{walletAddress}</p></button></div>
            <div><button onClick={showbalance}>show balance : <p>{balance}</p></button></div>
            <div><button onClick={checkallowance}>Check Allowance : <p>{ccheckallowance}</p></button></div>
            <hr/>
            <table align="center" border="1px solid black">
                <tr>
                <td>
                    <h1>Contribute to project </h1>
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
                </tr>
                <tr>
                <td>
                    <h1>change deadline</h1>
                    <form onSubmit={changeDeadline}>
                        <label>
                            ID:
                            <input
                                type="text"
                                name="id"
                            />
                        </label>
                        <label>
                            ID:
                            <input
                                type="date"
                                name="updatedate"
                            />
                        </label>
                        <button type="submit">claim</button>
                    </form>
                </td>
                <td>
                    <h1>Claim</h1>
                    <form onSubmit={claim}>
                        <label>
                            ID:
                            <input
                                type="text"
                                name="id"
                            />
                        </label>
                        <button type="submit">claim</button>
                    </form>
                </td>
                </tr>
                <tr>
                <td>
                    <h1>Trasfer ERC20 To from admin </h1>
                    <form onSubmit={transfererc20}>
                        <label>
                            to:
                            <input
                                type="text"
                                name="to"
                            />
                        </label>
                        <br/>
                        <label>
                            Amount To transfer:
                            <input
                                type="number"
                                name="amount"
                            />
                        </label>
                        <br/>
                        <button type="submit">Transfer</button>
                    </form>
                </td>
                <td>
                    <h1>Approve money: </h1>
                    <form onSubmit={aprroveMoney}>
                        <label>
                            Amount:
                            <input
                                type="number"
                                name="amount"
                            />
                        </label>
                        <br/>
                        <label>
                            Spender:
                            <input
                                type="text"
                                name="spender"
                            />
                        </label>
                        <br/>
                        <button type="submit">Approve</button>
                    </form>
                </td>
                </tr>
            </table>
            <hr />
            <button onClick={ss}>Fetch Projects and Investments</button>
            <table align="center" border="1px solid black">
                <td>
                    <h1>All Projects:</h1>
                    {projects.map((project, index) => (
                        <div key={index}>
                            <h2>Name: {project.name}</h2>
                            <h2>ID: {project.id}</h2>
                            <p>Funding Goal: ${project.fundingGoal}</p>
                            <p>Deadline: {project.deadline}</p>
                        </div>
                    ))}
                </td>
                <td>
                    <h1>All Investments:</h1>
                    {investment.map((inv, index) => (
                        <div key={index}>
                            <h2>Amount: {inv.amount}</h2>
                            <p>Claimed: {inv.claimed}</p>
                            <p>Active: {inv.active}</p>
                        </div>
                    ))}
                </td>
            </table>
        </div>
    );
}