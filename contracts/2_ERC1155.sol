// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./1_ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomCrowdfunding is ERC1155, Ownable {

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

    struct Investor {
        address investor;
        uint256 amount;
        uint256 timeOfInv;
        bool claimed;
        bool active;
    }

    struct Project {
        string name;
        uint256 id;
        uint256 fundingGoal;
        uint256 deadline;
        bool goalReached;
        uint256 totalRaised;
        uint256 totalInvestors;
        Investor[] ii;
        mapping(address => uint256) balances;
    }

    function getProject(uint256 id) public view returns(string memory, uint256, uint256, bool, uint256, uint256){
        return (projects[id].name, projects[id].fundingGoal, projects[id].deadline, projects[id].goalReached, projects[id].totalRaised, projects[id].totalInvestors);
    }

    function getInvestment(uint256 id) public view returns(uint256, uint256, bool, bool) {
        for(uint i=0; i<projects[id].totalInvestors; i++){
            if(projects[id].ii[i].investor == msg.sender){
                return (projects[id].balances[msg.sender], projects[id].ii[i].amount, projects[id].ii[i].claimed, projects[id].ii[i].active);
            }
        }
        return (0, 0, false, false);
    }

    function changeDeadline(uint256 id, uint256 updatedDeadline) public {
        projects[id].deadline = updatedDeadline;
    }

    function withdrawBefore24Hrs(uint256 id) public {
        uint256 balance = projects[id].balances[msg.sender];
        require(balance > 0, "No contribution to refund.");
        for (uint i=0; i<projects[id].totalInvestors; i++){
            if(projects[id].ii[i].investor == msg.sender && projects[id].ii[i].active && projects[id].ii[i].claimed==false){
                projects[id].ii[i].active = false;
                projects[id].ii[i].claimed = true;
                token.transfer(msg.sender, projects[id].ii[i].amount);
                _burn(msg.sender, id, projects[id].ii[i].amount);
                projects[id].ii[i].amount = 0;
                projects[id].totalRaised-=projects[id].balances[msg.sender];
                projects[id].balances[msg.sender] = 0;
            }
        }
    }

    function createProject(string memory _name, uint256 _fundingGoal, uint256 _deadline) public returns (uint256) {
        uint256 id = projectId;
        projects[id].fundingGoal = _fundingGoal;
        projects[id].deadline = _deadline;
        projects[id].name = _name;
        projects[id].id = projectId;
        projects[id].totalInvestors = 0;
        projectId++;
        return id;
    }

    function contribute(uint256 id, uint256 amount) public {
        require(projects[id].deadline > block.timestamp, "Crowdfunding deadline has passed.");
        require(amount > 0, "Contribution amount must be greater than 0.");
        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer token from sender.");
        _mint(msg.sender, id, amount, "x0123"); //reciept
        projects[id].balances[msg.sender] += amount;
        projects[id].totalRaised += amount;
        bool found=false;
        for (uint i=0; i<projects[id].totalInvestors; i++){
            if(projects[id].ii[i].investor == msg.sender){
                found = true;
                projects[id].ii[i].active = true;
                projects[id].ii[i].claimed = false;
                projects[id].ii[i].timeOfInv = block.timestamp;
                projects[id].ii[i].amount += amount;
            }
        }
        if(!found) { 
            projects[id].ii.push(Investor({ investor: msg.sender, amount: amount, claimed: false, timeOfInv: block.timestamp, active:true }));
            projects[id].totalInvestors++;
        }
        emit Contribution(id, msg.sender, amount);
    }

    function cclaim(uint256 id, address sender) private {
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
                if(!projects[id].ii[i].claimed && projects[id].ii[i].investor==sender){
                    projects[id].ii[i].claimed = true;
                    projects[id].ii[i].active = false;
                    projects[id].ii[i].amount = 0;
                }
            }
            emit Claim(id, sender, payout);
        } else {
            uint256 balance = projects[id].balances[sender];
            require(balance > 0, "No contribution to refund.");

            projects[id].balances[sender] = 0;
            token.transfer(sender, balance);
            _burn(sender, id, balance);

            for(uint i = 0 ; i<projects[id].totalInvestors; i++) {
                if(!projects[id].ii[i].claimed && projects[id].ii[i].investor==sender){
                    projects[id].ii[i].claimed = true;
                    projects[id].ii[i].active = false;
                    projects[id].ii[i].amount = 0;
                }
            }

            emit Refund(id, sender, balance);
        }
    }

    function claim(uint256 id) public {
        cclaim(id, msg.sender);
    }

    function calculateProfit(uint256 amount) private pure returns(uint256) {
        return amount*2;
    }

    event Contribution(uint256 indexed id, address indexed sender, uint256 amount);
    event Claim(uint256 indexed id, address indexed sender, uint256 amount);
    event Refund(uint256 indexed id, address indexed sender, uint256 amount);
}
