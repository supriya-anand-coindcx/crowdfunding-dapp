// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract FundingToken is ERC20, Ownable {
    constructor() ERC20("fundingToken", "CFT") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }   

}

contract ReceiptToken is ERC1155, Ownable {
    constructor() ERC1155("") {
        _mint(msg.sender, 1, 1000, "");
    }

    function mint(address to, uint256 tokenId, uint256 amount) public onlyOwner {
        _mint(to, tokenId, amount, "");
    }

    function burn(address _account, uint256 _id, uint256 _amount) public {
        _burn(_account, _id, _amount);
    }
}

contract CrowdFunding {
    struct Project {
        uint256 id;
        address ownerAddress;
        string name;
        uint256 fundingGoal;
        uint256 totalNFTs;
        uint256 deadline;
        mapping(address => uint256) investors;
        uint256 amountCollected;
    }

    event ProjectCreated(uint256 projectId, uint256 goal, uint256 deadline, uint256 totalNFTs, string name);
    event InvestmentMade(address indexed investor, uint256 indexed projectId, uint256 amount);
    event ProfitClaimed(address indexed investor, uint256 indexed projectId, uint256 profit);


    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public receiptToken; 
    ReceiptToken public receiptTokenContract;

    uint256 public numberOfProjects = 0;

    function createProject(string memory _name, uint256 _fundingGoal, uint256 _totalNFTs, uint256 _deadline) public returns (uint256) {
        require(_fundingGoal > 0, "Goal amount should be greater than zero");
        require(_deadline > block.timestamp, "Deadline should be in the future");
        require(_totalNFTs > 0, "Total number of NFTs should be greater than zero");


        Project storage project = projects[numberOfProjects++];

        project.ownerAddress = msg.sender;
        project.name = _name;
        project.fundingGoal = _fundingGoal;
        project.deadline = _deadline;
        project.amountCollected = 0;
        project.id = numberOfProjects;

        return numberOfProjects - 1;
    }

    function donateToProject(uint256 _id) public payable {
        uint256 amount = msg.value;

        Project storage project = projects[_id];

        project.investors[msg.sender] = amount;

        (bool sent,) = payable(address(this)).call{value: amount}("");
        require(sent, "Transaction unsuccessful");

        project.amountCollected = project.amountCollected + amount;

        // Mint ERC1155 receipt for investor
        receiptTokenContract.mint(msg.sender, _id, amount);

        // Update receiptToken mapping
        receiptToken[_id][msg.sender] += amount;
    }

    

    function getAllProjects() public view returns (string memory) {
        string memory allProjects;
        for (uint256 i = 0; i < numberOfProjects; i++) {
            Project storage project = projects[i];
            allProjects = string(abi.encodePacked(allProjects, "Project Name: ", project.name, "\n", "Funding Goal: ", project.fundingGoal, "\n", "Deadline: ", project.deadline, "\n", "Amount Collected: ", project.amountCollected, "\n\n"));
        }
        return allProjects;
    }

    function getProjectBalance(uint256 _projectId) public view returns (uint256) {
        require(_projectId < numberOfProjects, "Invalid project ID");

        Project storage project = projects[_projectId];
        return project.amountCollected;
    }

    function getTotalBalance() public view returns (uint256 totalBalance) {
        for (uint256 i = 0; i < numberOfProjects; i++) {
            totalBalance += projects[i].amountCollected;
        }
        return totalBalance;
    }


    function claimProfit(uint256 _projectId, uint256 _amount) public {
        Project storage project = projects[_projectId];
        uint256 investorContribution = receiptToken[_projectId][msg.sender];
        require(investorContribution > 0, "No contribution made by the investor");
        require(_amount <= investorContribution, "Cannot claim more than contributed");

        uint256 totalAmount = project.amountCollected;
        uint256 projectBalance = address(this).balance;
        uint256 profit = projectBalance * _amount / totalAmount;

        require(profit > 0, "No profit available to claim");
        receiptToken[_projectId][msg.sender] -= _amount;

        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transfer(msg.sender, profit);

        receiptTokenContract = ReceiptToken(address(this));
        receiptTokenContract.burn(msg.sender, _projectId, _amount);
    }


}