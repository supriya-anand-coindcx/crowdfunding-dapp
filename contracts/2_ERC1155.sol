// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./1_ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
    The following contract is an ERC1155 contract. The contract accepts ERC20 tokens from the investor and returns them a receipt
    The receipt states their share in return for their investment in the project

    The contract mainly has following functions:
    1. createProject(name, fundingGoal, deadline)
    2. contribute(projectId, amount)
    3. claimFunds(projectId)
    4. withdrawFunds(projectId)
*/
contract CustomCrowdfunding is ERC1155, Ownable {
    
    // Investores Data Structure
    struct Investor {
        address investorAddress;
        uint256 amount;
        uint256 timeOfInv;
        bool claimed;
        bool active;
    }

    // Projects Data Structure
    struct Project {
        string name;
        uint256 id;
        uint256 fundingGoal;
        uint256 deadline;
        bool goalReached;
        uint256 totalRaised;
        uint256 totalInvestors;
        Investor[] investor;
        mapping(address => uint256) balances;
    }

    string name;
    string symbol;

    mapping(uint256 => Project) public projects;
    uint256 public projectId = 0;

    CustomCrowdfundingToken public token;

    constructor(address tokenAddress) ERC1155("") {
        name = "PROJECT1155";
        symbol = "PJ1155";
        token = CustomCrowdfundingToken(tokenAddress);
    }

    // Events triggered in critical transactions
    event ProjectCreated(string _name, uint256 indexed id,uint256 _fundingGoal, uint256 _deadline);
    event Contribution(uint256 indexed id, address indexed sender, uint256 amount);
    event Claim(uint256 indexed id, address indexed sender, uint256 amount);
    event Refund(uint256 indexed id, address indexed sender, uint256 amount);

    // View function to get the details of a project when the projectId is provided
    function getProject(uint256 id) public view returns(string memory, uint256, uint256, bool, uint256, uint256) {
        return (projects[id].name, projects[id].fundingGoal, projects[id].deadline, projects[id].goalReached, projects[id].totalRaised, projects[id].totalInvestors);
    }

    function getInvestment(uint256 id) public view returns(uint256, uint256, bool, bool) {
        for(uint i=0; i<projects[id].totalInvestors; i++){
            if(projects[id].investor[i].investorAddress == msg.sender){
                return (projects[id].balances[msg.sender], projects[id].investor[i].amount, projects[id].investor[i].claimed, projects[id].investor[i].active);
            }
        }
        return (0, 0, false, false);
    }

    // The changeDeadline functionality is present only for the demo purpose of the project and can only be done by the owner of the contract
    function changeDeadline(uint256 id, uint256 updatedDeadline) public onlyOwner {
        projects[id].deadline = updatedDeadline;
    }

    // The withdrawFunds function allows the investors to withdraw their funds from the project within 24 hrs from their investment
    function withdrawFunds(uint256 id) public {
        uint256 balance = projects[id].balances[msg.sender];
        require(balance > 0, "No contribution to refund.");
        for (uint i=0; i<projects[id].totalInvestors; i++){
            if(projects[id].investor[i].investorAddress == msg.sender && projects[id].investor[i].active && projects[id].investor[i].claimed==false){
                require(block.timestamp < (projects[id].investor[i].timeOfInv + 5 minutes), "Cannot Withdraw past 24 hrs");
                projects[id].investor[i].active = false;
                projects[id].investor[i].claimed = true;
                token.transfer(msg.sender, projects[id].investor[i].amount);
                _burn(msg.sender, id, projects[id].investor[i].amount);
                projects[id].investor[i].amount = 0;
                projects[id].totalRaised-=projects[id].balances[msg.sender];
                projects[id].balances[msg.sender] = 0;
            }
        }
    }

    // The createProject function allows the fundraisers to add a project for crowdfunding and once a project is created, an ID is returned
    function createProject(string memory _name, uint256 _fundingGoal, uint256 _deadline) public onlyOwner returns (uint256) {
        uint256 id = projectId;
        projects[id].fundingGoal = _fundingGoal;
        projects[id].deadline = _deadline;
        projects[id].name = _name;
        projects[id].id = projectId;
        projects[id].totalInvestors = 0;
        projectId++;
        emit ProjectCreated(_name,id, _fundingGoal, _deadline);
        return id;
    }
    
    /*
        contribute function allows the investors to contribute to a particular project and the investors
        receive their relevant share of NFT for the same.
    */
    function contribute(uint256 id, uint256 amount) public {
        require(projects[id].deadline > block.timestamp, "Crowdfunding deadline has passed.");
        require(amount > 0, "Contribution amount must be greater than 0.");
        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer token from sender.");
        _mint(msg.sender, id, amount, "x0123"); //reciept
        projects[id].balances[msg.sender] += amount;
        projects[id].totalRaised += amount;
        bool found=false;
        for (uint i=0; i<projects[id].totalInvestors; i++){
            if(projects[id].investor[i].investorAddress == msg.sender){
                found = true;
                projects[id].investor[i].active = true;
                projects[id].investor[i].claimed = false;
                projects[id].investor[i].timeOfInv = block.timestamp;
                projects[id].investor[i].amount += amount;
            }
        }
        if(!found) { 
            projects[id].investor.push(Investor({ investorAddress: msg.sender, amount: amount, claimed: false, timeOfInv: block.timestamp, active:true }));
            projects[id].totalInvestors++;
        }
        emit Contribution(id, msg.sender, amount);
    }

    /*
        internalClaim is a private function to return the ERC tokens back to the investors along with the profit earned
        While returnig the ERC20 token, the function makes sure to burn the user's share of ERC1155.
    */
    function internalClaim(uint256 id, address sender) private {
        require(projects[id].deadline <= block.timestamp, "Crowdfunding deadline has not yet passed.");

        if (projects[id].totalRaised >= projects[id].fundingGoal) {
            uint256 balance = projects[id].balances[sender];
            require(balance > 0, "No contribution to claim.");

            uint256 payout = calculateProfit(balance);
            token.transfer(sender, payout);
            _burn(sender, id, balance);

            projects[id].totalRaised -= projects[id].balances[sender];
            projects[id].goalReached = true;
            projects[id].balances[sender] = 0;

            for(uint i = 0 ; i<projects[id].totalInvestors; i++) {
                if(!projects[id].investor[i].claimed && projects[id].investor[i].investorAddress==sender){
                    projects[id].investor[i].claimed = true;
                    projects[id].investor[i].active = false;
                    projects[id].investor[i].amount = 0;
                }
            }
            emit Claim(id, sender, payout);
        } else {
            uint256 balance = projects[id].balances[sender];
            require(balance > 0, "No contribution to refund.");

            projects[id].totalRaised -= projects[id].balances[sender];
            projects[id].balances[sender] = 0;
            token.transfer(sender, balance);
            _burn(sender, id, balance);

            for(uint i = 0 ; i<projects[id].totalInvestors; i++) {
                if(!projects[id].investor[i].claimed && projects[id].investor[i].investorAddress==sender){
                    projects[id].investor[i].claimed = true;
                    projects[id].investor[i].active = false;
                    projects[id].investor[i].amount = 0;
                }
            }

            emit Refund(id, sender, balance);
        }
    }

    /*
        Given the id of the project, the investor can claim for his ERC20 tokens back
        The claimFunds function internally calls the private function internalClaim(uint256 id, address sender) which puts
        the checks on the investment of the investor as well as the project deadline.
        ERC20 tokens can only be claimed once the project deadline is met
    */
    function claimFunds(uint256 id) public {
        internalClaim(id, msg.sender);
    }
    
    // CalculateProfit function returns the amount of profit that the investors are supposed to get
    function calculateProfit(uint256 amount) private pure returns(uint256) {
        return amount*2;
    }
}