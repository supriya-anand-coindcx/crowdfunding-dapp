# crowdfunding-dapp
A Web3 crowdfunding platform using custom ERC20 tokens and ERC1155 NFTs to enable contributors to become project shareholders, and the ability to claim proportional profits when the project becomes profitable.

ERC20 - T1
NFT(ERC 1155) - P1

Goal - 100 T1
P1 tokens - 1000
deadline - 6 days

shares = contribution/Goal * total number of NFTs
A -> 10T1 = 10/100*1000 = 100
B -> 2 T1 = 2/100*1000 = 20

Goal achieved

A -> 10T1 = 10/100*1000 = 100 P1 -> 200P1 -> 20T1
B -> 2 T1 = 2/100*1000 = 20 P1 -> 40P2 -> 4 T1

Net profit = profit_multipier * invested_P1 * (P1 in terms of T1)

Withdraw -
Refund all - 

0. createProject
-> Initialize Goal(in T1 units), Deadline, number of P1 tokens
-> number of P1 tokens
-> Append to the list of projects if exists
1. getallProjects(Read from the list of projects)
2. contribute/investInProject(ID, amount)
-> User will enter the amount of T1 tokens which they want to pledge
-> The same amount of T1 tokens will be minted and ransaferred to our CF contract
-> Map user address with amount of T1 tokens
-> We will calculate number of P1 tokens to be given to the user
-> We will mint and transfer calculated number of P1 tokens to the user's address.
4. Withdraw -  Iterate through map - InvestorContribution and find the contributer, and transfer all the ERC20 tokens back to their respective contributers and burn(?) their respective P1 tokens if ERC20 transaction was done lesser than 24 hrs ago.
5. RefundAll - Iterate through map - InvestorContribution, and transfer all the ERC20 tokens back to their respective contributers and burn(?) their respective P1 tokens.
7. ClaimProfit - 
-> Iterate through map - InvestorContribution and find the investor's contribution.
-> Check if the number of P1 tokens they want to claim is lesser than or equal to their P1 shares.
-> calculate the profit using the formula above and return the profit in terms of T1 tokens to the user.


