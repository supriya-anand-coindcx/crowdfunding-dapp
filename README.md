# crowdfunding-dapp
A Web3 crowdfunding platform using custom ERC20 tokens and ERC1155 NFTs to enable contributors to become project shareholders, and the ability to claim proportional profits when the project becomes profitable.

ERC20 - T1 (This will be our token for funding)
NFT(ERC 1155) - P1 (Here 1 is the id of the project, so we will have separate ERC 1155 tokens for separate projects confirmed from Yash).

**Example Use case:**

Goal - 100 T1
P1 tokens - 1000
contribution = 10T1
deadline - 6 days (we will cater our deadline via a bool if yes -> deadline met, else not)

_Formula_
**sharesToBeGivenToinvestor** = contribution/Goal * total number of NFTs

Examples:

A _user_ -> 10T1 = 10/100*1000 = 100 P1
B _user_ -> 2 T1 = 2/100*1000 = 20 P1


## When Goal achieved

_Formula_
Net profit for user = profit_multipier * invested_P1 * ratio(Goal in terms of P1)

eg
Lets say after goal achieved the company went 2x

so profit_multipier = 2
invested P1 for user A = 100P1


Net profit for A = 2 * 100 * 100/1000 = 4 T1 which is twice the amt he invested
 

# Contract functions:

1. createProject 
  - Initialize Goal(in T1 units), Deadline, number of P1 tokens, name
  - number of P1 tokens
  - Append to the list of projects if exists
  - mint P1 tokens
  - return project id

2. getallProjects(Read from the list of projects)
  - simply return the project with data

3. contribute/investInProject(ID, amount)
  - User will enter the amount of T1 tokens which they want to pledge
  - The same amount of T1 tokens will be minted and ransaferred to our CF contract
  - Map user address with amount of T1 tokens
  - We will calculate number of P1 tokens to be given to the user
  - We will mint and transfer calculated number of P1 tokens to the user's address.

4. Withdraw   
  - 24hr check otherwise return error
  - Iterate through map 
  - InvestorContribution and find the contributer, and transfer all the ERC20 tokens back to their respective contributers and burn(?) their respective P1 
  - ask about the burn thing

5. RefundAll 
  - Iterate through map - InvestorContribution, 
  - and transfer all the ERC20 tokens back to their respective contributers and burn(?) their respective P1 tokens.
  - ask about the burn thing


6. ClaimProfit - 
  - Iterate through map - InvestorContribution and find the investor's contribution.
  - Check if the number of P1 tokens they want to claim is lesser than or equal to their P1 shares.
  - calculate the profit using the formula above and return the profit in terms of T1 tokens to the user.
  - remove from investor from map and burn 1155 for them


