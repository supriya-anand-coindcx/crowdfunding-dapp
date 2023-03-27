// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract FundingToken is ERC20, Ownable {
    constructor() ERC20("FundingToken", "CFT") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
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
        // _mint(msg.sender, 1, 100000000, ""); // should not mint
        //DOUBT how to create id for receipt token
    }

    function mint(address to, uint256 tokenId, uint256 amount) public onlyOwner {
        _mint(to, tokenId, amount, "");
    }

    function burn(address _account, uint256 _id, uint256 _amount) public {
        _burn(_account, _id, _amount);
    }
}

contract CrowdFunding {
    struct Pair {
        uint256 timestamp;
        uint256 amount;
    }
    struct Project {
        uint256 id;
        address ownerAddress;
        string name;
        uint256 fundingGoal;
        uint256 totalNFTs;
        uint256 deadline;
        address[] investorArr; //a shadow array to maintain the list of investors
        mapping(address => Pair) investors;
        uint256 amountCollected;
    }

    uint128 receiptTokenToFundingTokenRatio = 1;

    // event ProjectCreated(uint256 projectId, string name, uint256 goal, uint256 deadline ); // no need
    event InvestmentMade(address indexed investor, uint256 indexed projectId, uint256 amount);
    event ProfitClaimed(address indexed investor, uint256 indexed projectId, uint256 profit);


    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public receiptToken; 
    //TO CONFIRM: it is mapped to projectId=>map(address => amount)

    ReceiptToken public receiptTokenContract; //DOUBT do we need to initialise this?

    uint256 public numberOfProjects = 0;

    function createProject(string memory _name, uint256 _fundingGoal, uint256 _deadline) public returns (uint256) {
        require(_fundingGoal > 0, "Goal amount should be greater than zero");
        require(_deadline > block.timestamp, "Deadline should be in the future");
        // require(_totalNFTs > 0, "Total number of NFTs should be greater than zero");


        Project storage project = projects[numberOfProjects++];

        project.ownerAddress = msg.sender;
        project.name = _name;
        project.fundingGoal = _fundingGoal;
        project.deadline = _deadline;
        project.amountCollected = 0;
        project.id = numberOfProjects;
        //tto initiate investorArray

        // emit ProjectCreated(numberOfProjects, _name, _fundingGoal, _deadline); // no need since we are returing the ID

        return numberOfProjects;
    }

    function donateToProject(uint256 _id, uint256 amount) public payable returns (ReceiptToken tokens) {

        Project storage project = projects[_id];

        project.investors[msg.sender].amount = amount;
        project.investors[msg.sender].timestamp = block.timestamp;
        project.investorArr.push(msg.sender);


        (bool sent,) = payable(address(this)).call{value: amount}("");
        require(sent, "Transaction unsuccessful");

        project.amountCollected = project.amountCollected + amount;

        // Mint ERC1155 receipt for investor
        receiptTokenContract.mint(msg.sender, _id, amount); // here we are keeping the ratio same for 1155 and erc 20

        // Update receiptToken mapping
        receiptToken[_id][msg.sender] += amount * receiptTokenToFundingTokenRatio; // updated the mapping of the investor's id with the amt of receipt tokens given

        return ReceiptToken(); //DOUBT create object and return that amt

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

        require(projects[_projectId].deadline>0, "Invalid project ID"); // DOUBT is this right?
        // require(_projectId < numberOfProjects, "Invalid project ID");

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
        uint256 receiptTokensWithInvestor = receiptToken[_projectId][msg.sender];
        uint256 investorContribution = receiptTokensWithInvestor * receiptTokenToFundingTokenRatio;
        require(receiptTokensWithInvestor > 0, "No contribution made by the investor");
        require(_amount <= investorContribution, "Cannot claim more than contributed");
        require(project.deadline < block.timestamp, "Cannot claim before deadline");
        require(project.fundingGoal <= project.amountCollected, "No profits, please initiate refund call");

        uint256 totalAmount = project.amountCollected;
        uint256 profit_multiplier = 2; // assuming that the profits are 2x
        uint256 profit = profit_multiplier * _amount * receiptTokenToFundingTokenRatio; //TO CONFIRM THIS FORMULA

        require(profit > 0, "No profit available to claim");
        receiptToken[_projectId][msg.sender] -= _amount; 

        uint256 totalTransferAmount = (_amount*receiptTokenToFundingTokenRatio)+profit;

        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transfer(msg.sender, totalTransferAmount);

        project.amountCollected -= totalTransferAmount;

        receiptTokenContract = ReceiptToken(address(this)); // DOUBT TO BE VERIFIED
        receiptTokenContract.burn(msg.sender, _projectId, _amount);
    }

    function refund(uint256 _projectId) public {
        Project storage project = projects[_projectId];
        uint256 receiptTokensWithInvestor = receiptToken[_projectId][msg.sender];
        uint256 investorContribution = receiptTokensWithInvestor * receiptTokenToFundingTokenRatio;
        require(investorContribution > 0, "No contribution made by the investor");
        require(project.deadline < block.timestamp, "Cannot claim before deadline");

        
        uint256 totalTransferAmount = investorContribution;

        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transfer(msg.sender, totalTransferAmount);

        project.amountCollected -= totalTransferAmount;

        receiptToken[_projectId][msg.sender] = 0;
        receiptTokenContract = ReceiptToken(address(this)); // DOUBT TO BE VERIFIED
        receiptTokenContract.burn(msg.sender, _projectId, totalTransferAmount);
    }
    

    function withdraw(uint256 _projectId) public {
        
        Project storage project = projects[_projectId];
        uint256 investorContribution = receiptToken[_projectId][msg.sender];
        require(investorContribution > 0, "No contribution made by the investor");
       //TO CORRECT: 
        require(block.timestamp < (projects[numberOfProjects - 1].deadline + 1 minutes), "Withdrawal not allowed yet, you need to wait 1 minute before withdrawl");
        //TO DISCUSS: whether to put a check to see if the deadline is not over?
        require(project.amountCollected > 0, "No funds available for withdrawal");

        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transfer(msg.sender, investorContribution);

        project.amountCollected -= investorContribution;

        receiptToken[_projectId][msg.sender] = 0;
        receiptTokenContract = ReceiptToken(address(this)); // DOUBT TO BE VERIFIED
        receiptTokenContract.burn(msg.sender, _projectId, investorContribution);
        
    }
}