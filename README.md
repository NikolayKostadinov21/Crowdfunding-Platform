# Crowdfunding Platform

# Overview

| Contracts                 | Purpose                                                                   | SLOC |
|---------------------------|---------------------------------------------------------------------------|------|
| CrowdFundingPlatform.sol  | Crowdfunding Platform where you can create projects and invest in them    | 335  |
| FundMeFaucet.sol          | Represents the faucet where you can request FundMe tokens                 | 75   |
| FundMeToken.sol           | Represents the FundMe token                                               | 17   |
| UUPSUtils.sol             | Utils Shared Library to facilitate Proxy and Proxiable contracts          | 38   |
| UUPSProxy.sol             | Proxy contract compliant with eip-1822 and eip-1967                       | 34   |
| UUPSProxiable.sol         | Proxiable abstract contract                                               | 68   |

# Architecture

# Crowdfunding project workflow

## Obtaining FundMe tokens
Before using the crowdfunding platform contract, it's mandatory to exchange some ETH for FundMe tokens.

That's possible from the FundMe Faucet contract.
The steps are the following:
```
1. Deposit X amount of funds to receive X amount of FundMe tokens using the depositFunds function in the FundMeFaucet contract.

2. Once you've deposited X funds, you can request X tokens from the requestTokens function, also located in the FundMeFaucet contract.
Note: You cannot request FundMe tokens until the lock time of 1 minute is surpassed

3. After you've acquired some FundMe tokens, then you can invest them in the crowdfunding platform based on your choice
```

Here is an image illustrating just that:
![Obtaining FundMe tokens workflow](<Images/Obtaining FundMe tokens workflow.png>)

## CrowdFundingPlatform contract functions

#### initializeCrowdfundingProject
The function helps initialize new crowdfunding project.
Everyone can invoke this function and create new crowdfunding project
##### Lifecycle
```
1. Increasing the value of counter by one
2. Assigning the appropriate values for the newly created project
3. Emit an event
```

#### terminateCrowdfundingProject
If the project's timeline hasn't been reached yet and if the project is not successful, the owner of the project can terminate it
##### Lifecycle
```
1. Check whether the project exists and, if it is unsuccessful, if it is before its timeline, if you are the project owner
2. Exceed the timeline of the project
3. Make the project unsuccessful
4. Emit an event
```

#### investFunds
Investing funds in the form of FundMe tokens into a specific project.
##### Lifecycle
```
1. Check if the project exists, if it's before the timeline and if it's already achieved its goal
2. Check is @param amount > 0
3. Transfer the funds to the project
4. Update the invested funds in the crowdFundingProjects and customerInvestedFunds mappings
5. If after the transfer, the invested funds are greater or equal the funding goal, then make the project successful
6. Emit an event
```

#### revokeFunds
Revoke function to help in case investor wants to unstake certain amount of FundMe tokens from a project
##### Lifecycle
```
1. Check if the product exists and if it's before its timeline
2. Check if investor has any investments in the particular project
3. Check if the project already achieved its goal
4. Transfer the requested amount to the investor
5. Decrease the invested funds in the project
6. Decrease the amount of funds in the mapping customerInvestedFunds for the investor
7. Emit an event
```

#### withdrawFunds
The project owner can withdraw the total acquired funds if their project is successful
##### Lifecycle
```
1. Check if the project is existing, is finished and is successful
2. Check if it's the owner that invokes the function
3. Transfer tokens to owner of the project
4. Delete the project
5. Emit an event
```

#### refundFunds
If certain project fails to reach the funding goal until its timeline, all investors can refund their deposits.
##### Lifecycle
```
1. Checks if the project exists and if it's unsuccessful
2. Check if beneficiary has invested something in the particular project
3. If the investor has already refunded all of their tokens, prevent them from invoking this function for this project
4. Transfer tokens to beneficiary
5. Emit an event
6. Delete the investor's staked funds in the project
7. If everyone has refunded successfully their tokens, delete the project
```

#### updateCode
* Updates the address of the logic contract
* Can be invoked only by the owner of the platform contract
* Implementation is in UUPSProxiable contract


# Tests
