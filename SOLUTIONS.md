# Damn Vulnerable DeFi - Solutions

## 1. Unstoppable

This lender contract can be broken by sending DVT tokens to it without using its `depositTokens` function.  
See [unstoppable.challenge.js](./test/unstoppable/unstoppable.challenge.js)


## 2. Naive receiver

The receiver's funds can be drained by executing flash loans on his behalf (initiated by the attacker).
See [naive-receiver.challenge.js](./test/naive-receiver/naive-receiver.challenge.js) and [NaiveReceiverAttack.sol](./contracts/attacker-contracts/NaiveReceiverAttack.sol).  


## 3. Truster

This lender contract allows us to call any function during flash loan execution on its behalf. Therefore, simply call the ERC20 token's `approve` function from the lender contract.  
See [truster.challenge.js](./test/truster/truster.challenge.js) and [NaiveReceiverAttack.sol](./contracts/attacker-contracts/TrusterAttack.sol).


