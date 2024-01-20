# PiGHOBank Contract

## Overview
PiGHOBank is designed as a personal savings account. It operates using the GHO token. The purpose of this contract is to encourage and support disciplined savings by providing a platform where users can store and lock their GHO tokens over a period of time, preventing them from spending their funds all at once.

The contract provides a structured saving model, making users plan their withdrawals according to specified periods. This feature helps to reinforce financial discipline.

In case of emergencies, PiGHOBank has a thoughtful feature. When creating a deposit, users can assign a trusted family member or friend who can release the funds in emergency situations to handle unforeseen expenses. The act of requesting help to access the funds serves as a psychological barrier, deterring users from making impulsive withdrawals for unnecessary cases.

PiGHOBank merges the concepts of traditional savings accounts with the innovative power of blockchain technology, fostering prudent financial habits within the transparency and security of the Ethereum network.

[Frontend Repository and Demo](https://github.com/pighobank/pighobank-interface)
## Functions

### createDeposit
This function is used to create a new deposit. It takes in the amount to be deposited, the emergency release signer's address, and the number of periods, and creates a new deposit object in the `deposits` mapping.

### addDeposit
This function is used to add funds to an existing deposit. It takes in the deposit index and the amount to be added. The amount would then be transferred from the sender's account to the contract, and it updates the deposit's amount.

### withdraw
This function allows a user to withdraw a specified amount from a specific deposit, as long as the amount is less than or equal to the withdrawable amount calculated.

### emergencyRelease
Enables an emergency release signer to perform an emergency release of tokens from a specified deposit.

### getWithdrawableAmount
This function calculates the amount that can currently be withdrawn from a specific deposit.
