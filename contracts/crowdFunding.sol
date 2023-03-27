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
        address[] investorArr; //a shadow array to maintain the list of investors
        mapping(address => uint256) investors;
        uint256 amountCollected;
    }

    event ProjectCreated(uint256 projectId, string name, uint256 goal, uint256 deadline );
    event InvestmentMade(address indexed investor, uint256 indexed projectId, uint256 amount);
    event ProfitClaimed(address indexed investor, uint256 indexed projectId, uint256 profit);


    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public receiptToken; 
    //TO CONFIRM: it is mapped to project=>map(address => amount)
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
        //tto initiate investorArray
        emit ProjectCreated(numberOfProjects, _name, _fundingGoal, _deadline);

        return numberOfProjects - 1;
    }

    function donateToProject(uint256 _id) public payable {
        //TO DISCUSS: we might need to capture the time when the donation was made in order to process the time till which the funds can be withdrawn 
        uint256 amount = msg.value;

        Project storage project = projects[_id];

        project.investors[msg.sender] = amount;
        project.investorArr.push(msg.sender);


        (bool sent,) = payable(address(this)).call{value: amount}("");
        require(sent, "Transaction unsuccessful");

        project.amountCollected = project.amountCollected + amount;

        // Mint ERC1155 receipt for investor
        receiptTokenContract.mint(msg.sender, _id, amount);

        // Update receiptToken mapping
        receiptToken[_id][msg.sender] += amount;

        //TO DISCUSS: whether to emit the receipt token or to return the RECEIPT TOKEN?
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
        uint fundingGoal = project.fundingGoal;
        uint256 profit_multiplier = totalAmount/fundingGoal;
        uint256 profit = profit_multiplier * _amount / totalAmount; //TO CONFIRM THIS FORMULA

        require(profit > 0, "No profit available to claim");
        receiptToken[_projectId][msg.sender] -= _amount; 

        uint256 totalTransferAmount = _amount+profit;

        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transfer(msg.sender, totalTransferAmount);

        project.amountCollected -= totalTransferAmount;

        receiptTokenContract = ReceiptToken(address(this)); //TO BE VERIFIED
        receiptTokenContract.burn(msg.sender, _projectId, _amount);
    }
    

    function withdraw(uint256 _projectId) public {
        
        Project storage project = projects[_projectId];
        uint256 investorContribution = receiptToken[_projectId][msg.sender];
        require(investorContribution > 0, "No contribution made by the investor");
       //TO CORRECT: 
        require(block.timestamp < (projects[numberOfProjects - 1].deadline + 1 days), "Withdrawal not allowed yet, you need to wait 24 hours before withdrawl");
        //TO DISCUSS: whether to put a check to see if the deadline is not over?
        require(project.amountCollected > 0, "No funds available for withdrawal");

        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transfer(msg.sender, investorContribution);

        project.amountCollected -= investorContribution;

        receiptToken[_projectId][msg.sender] = 0;
    }

    //TO ADD: RefundAll function

}