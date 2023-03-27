// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

contract FundingToken is ERC20, Ownable {
    constructor() ERC20("fundingToken", "CFT") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint _amount) public {
        _burn(msg.sender, _amount);
    }   

}

// interface IReceiptToken is IERC1155 {
//   function mint(
//     uint id,
//     uint amount,
//     string calldata newURI
//   ) external;

//   function updateURI(uint id, string calldata newURI) external;

//   function changeInvestContractAddress(address newAddress) external;

//   function burn(
//     address from,
//     uint id,
//     uint amount
//   ) external;
// }

 contract ReceiptToken is ERC1155, Ownable {
    // address private crowdFundingContractAddress;
    // mapping(uint => string) private tokenURIs;
    // modifier investOnly() {
    //     require(msg.sender == crowdFundingContractAddress, 'NOT_INVEST_CONTRACT');
    //     _;
    // }

    constructor() ERC1155('') {
        // require(_crowdFundingContractAddress != address(0), 'INVEST_ADDR_IS_ZERO');
        // crowdFundingContractAddress = _crowdFundingContractAddress;
    }

    function mint(
        uint id,
        uint amount,
        address to,
        string calldata newURI
    ) external onlyOwner {
        _mint(to, id, amount, '');
        // _setURI(newURI, id);
    }

    // function _setURI(string calldata newURI, uint id) internal {
    //     tokenURIs[id] = newURI;
    // }

    // function updateURI(uint id, string calldata newURI) external investOnly {
    //     _setURI(newURI, id);
    // }

    // function uri(uint id) public view override returns (string memory) {
    //     return tokenURIs[id];
    // }

    function burn(
        address from,
        uint id,
        uint amount
    ) external onlyOwner {
        _burn(from, id, amount);
    }
}

contract CrowdFunding is Ownable, ERC1155Holder{
    enum Status{
        LIVE,
        GOAL_ACHIEVED,
        REFUND
    }
    struct Pair {
        uint timestamp;
        uint amount;
    }
    struct Project {
        Status status;
        string name;
        uint goalNFTTokens;
        uint NFTtokensOwnedByUsers;
        uint deadline;
        uint goalAchievedTimestamp;
    }

    error WrongAmountOfFundingTokens(uint256 received, uint256 required);
    error TooManyTokens(uint256 received, uint256 available);
    

    event ProjectCreated(uint projectId, string name, uint goal, uint deadline );
    event InvestmentMade(address indexed investor, uint indexed projectId, uint amount);
    event ProfitClaimed(address indexed investor, uint indexed projectId, uint profit);
    event ProjectFinalized(uint id, Status outcome);
    event TokensTransferredBack(address indexed investor, uint projectId, uint noOfTokens);
    event NFTContractSet(address _contract);

    uint pricePerNFTToken;
    address private receiptTokenContract;
    mapping(address => uint) investmentTimestamp;
    mapping(uint => Project) private projects;
    //mapping(uint => mapping(address => uint)) public receiptToken; 
    //TO CONFIRM: it is mapped to project=>map(address => amount)
    //ReceiptToken public receiptTokenContract;

    uint public numberOfProjects = 0;

    modifier receiptTokenContractIsSet() {
        require(receiptTokenContract != address(0), 'NFT_CONTRACT_NOT_SET');
        _;
    }

    function createProject(string memory _name, uint _goalNFTTokens, uint _deadline, string calldata metadataURI) external receiptTokenContractIsSet{
        require(_goalNFTTokens > 0, "Goal amount should be greater than zero");
        require(_deadline > block.timestamp, "Deadline should be in the future");

        Project memory newProject = Project(Status.LIVE, _name, _goalNFTTokens, 0, _deadline, 0);
        uint id = numberOfProjects++;
        projects[id] = newProject;

        //deploy 1155 first and set the receipt token contract address in receiptTokenContract
        ReceiptToken(receiptTokenContract).mint(id, _goalNFTTokens, msg.sender, metadataURI);

        emit ProjectCreated(id, _name, _goalNFTTokens, _deadline);
    }

    function finalizeProjectCompletion(uint id) external {
        Project memory project = getProjectInfo(id);
        require(project.status == Status.LIVE, 'SALE_NOT_ACTIVE');
        if (block.timestamp > project.deadline && project.NFTtokensOwnedByUsers != project.goalNFTTokens) {
            project.status = Status.REFUND;
        } else if (project.NFTtokensOwnedByUsers == project.goalNFTTokens) {
            project.status = Status.GOAL_ACHIEVED;
            project.goalAchievedTimestamp = block.timestamp;
        } else {
            revert('SALE_NOT_OVER');
        }
        projects[id] = project;
        emit ProjectFinalized(id, project.status);
    }

    function invest(uint _id, uint tokenAmount) public payable {
        Project memory project = getProjectInfo(_id);
        require(project.status == Status.LIVE, 'SALE_NOT_ACTIVE');
        require(project.deadline > block.timestamp, 'SALE_IS_OVER');
        if (tokenAmount > project.goalNFTTokens - project.NFTtokensOwnedByUsers) {
        revert TooManyTokens(tokenAmount, project.goalNFTTokens - project.NFTtokensOwnedByUsers);
        } else if (msg.value != tokenAmount * pricePerNFTToken) {
        revert WrongAmountOfFundingTokens(msg.value, tokenAmount * pricePerNFTToken);
        }
        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transferFrom(msg.sender, address(this), tokenAmount * pricePerNFTToken);
        ReceiptToken(receiptTokenContract).safeTransferFrom(address(this), msg.sender, _id, tokenAmount, '');

        project.NFTtokensOwnedByUsers += tokenAmount;
        investmentTimestamp[msg.sender] = block.timestamp;
        projects[_id] = project;
        emit InvestmentMade(msg.sender, _id, tokenAmount);
    }

    function requestFundingToken(uint amount) public {
        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transfer(msg.sender, amount);
    }
    

    // function getAllProjects() public view returns (string memory) {
    //     string memory allProjects;
    //     for (uint i = 0; i < numberOfProjects; i++) {
    //         Project memory project = projects[i];
    //         allProjects = string(abi.encodePacked(allProjects, "Project Name: ", project.name, "\n", "Funding Goal: ", project.goalNFTTokens, "\n", "Deadline: ", project.deadline, "\n", "Amount Collected: ", getTotalFundsContribution(project), "\n\n"));
    //     }
    //     return allProjects;
    // }


    function getProjectBalance(uint _projectId) public view returns (uint) {
        require(_projectId < numberOfProjects, "Invalid project ID");

        Project memory project = projects[_projectId];
        return project.NFTtokensOwnedByUsers;
    }

    function getTotalFundsContribution(Project memory project) private view returns (uint)
    {
        return project.NFTtokensOwnedByUsers*pricePerNFTToken;
    }
    
    function withdraw(uint id) public {
        
        Project storage project = projects[id];
        ReceiptToken receiptToken = ReceiptToken(receiptTokenContract);
        uint userTokens = receiptToken.balanceOf(msg.sender, id);
        require(userTokens > 0, "No contribution made by the investor");
        uint withdrawalAmount = userTokens * pricePerNFTToken;
        require(block.timestamp < project.deadline, "WITHDRAWL_NOT_ALLOWED");
        require(block.timestamp < (investmentTimestamp[msg.sender] + 1 minutes), "Withdrawal not allowed yet, you need to wait 24 hours before withdrawl");
        require(getTotalFundsContribution(project) > 0, "No funds available for withdrawal");

        receiptToken.safeTransferFrom(msg.sender, address(this), id, userTokens, '');
        emit TokensTransferredBack(msg.sender, id, userTokens);

        FundingToken fundingTokenContract = FundingToken(address(this));
        fundingTokenContract.transfer(msg.sender, withdrawalAmount);

        project.NFTtokensOwnedByUsers -= userTokens;
    }

    function getProjectInfo(uint id) private view returns (Project memory) {
        return projects[id];
    }

    function setReceiptTokenContract(address _contract) external onlyOwner {
        require(receiptTokenContract == address(0), 'NFT_CONTRACT_ALREADY_SET');
        require(_contract != address(0), 'NFT_ADDR_IS_ZERO');
        receiptTokenContract = _contract;
        emit NFTContractSet(_contract);
    }

    function claimProfits(uint id) external {
        Project memory project = getProjectInfo(id);
        require(block.timestamp > project.deadline , 'PROJECT_STILL_LIVE');
        ReceiptToken receiptToken = ReceiptToken(receiptTokenContract);
        uint userTokens = receiptToken.balanceOf(msg.sender, id);
        require(userTokens > 0, 'REFUND_ZERO_BALANCE');
        uint refundAmount = userTokens * pricePerNFTToken * hrsPassedSinceGoalCompletion(block.timestamp-project.goalAchievedTimestamp) * 2;
        project.NFTtokensOwnedByUsers -= userTokens;
        projects[id] = project;
        receiptToken.safeTransferFrom(msg.sender, address(this), id, userTokens, '');
        emit TokensTransferredBack(msg.sender, id, userTokens);

        FundingToken fundingTokenContract = FundingToken(address(this));
        bool result = fundingTokenContract.transfer(msg.sender, refundAmount);
        require(result, 'REFUNDTOKEN_TRANSFER_FAILED');

        emit ProfitClaimed(msg.sender, id, refundAmount);
    }

    function hrsPassedSinceGoalCompletion (uint timestamp) private pure returns (uint) {
        uint seconds_per_day = 60*60*24;
        uint secs = (timestamp / seconds_per_day);
        uint hrs = (secs / seconds_per_day)/60;
        return hrs;
    }

    //TO ADD: RefundAll function

}









