# Crowdfunding-Platform

## Steps in the main functions 

#### investFunds

```
1. Check if the project exists and if it's still going, i.e. not successful, fundingGoal not achieved
2. Amount > 0
3. transfer the funds to the project
4. update the invested funds in the crowdFundingProjects and customerInvestedFunds mappings
5. If after the transfer, the invested funds are greater or equal the funding goal, then make the project successful
6. Emit an event
```

#### withdrawFunds
```
1. Check if it's the owner that invokes the function
2. Check if the project is existing, is finished and is successful, if yes go to 3.
3. transfer tokens to owner of the project
4. Delete the project
5. Emit an event
```

#### refundFunds
```
1. Check if beneficiary has invested something in the particular campaign
   1.1 if yes, has he already refunded all of his tokens -> if that's true prevent him from repeating this function
   1.2 if no, go to 2.
2. Transfer tokens to beneficiary
3. If everyone has refunded successfully their tokens -> Delete the campaign
4. Emit an event
```