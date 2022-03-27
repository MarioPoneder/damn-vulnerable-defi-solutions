# Damn Vulnerable DeFi - Solutions

## 1. Unstoppable

This lender contract can be broken by sending DVT tokens to it without using its `depositTokens` function.  
See [unstoppable.challenge.js](./test/unstoppable/unstoppable.challenge.js)


## 2. Naive receiver

The receiver's funds can be drained by executing flash loans on his behalf (initiated by the attacker).  
See [naive-receiver.challenge.js](./test/naive-receiver/naive-receiver.challenge.js) and [NaiveReceiverAttack.sol](./contracts/attacker-contracts/NaiveReceiverAttack.sol).


## 3. Truster

This lender contract allows us to call any function during flash loan execution on its behalf. Therefore, simply call the ERC20 token's `approve` function from the lender contract.  
See [truster.challenge.js](./test/truster/truster.challenge.js) and [TrusterAttack.sol](./contracts/attacker-contracts/TrusterAttack.sol).


## 4. Side entrance

This lender contract allows us to call its `deposit` function during flash loan execution without failure. Therefore we can easily withdraw the funds after "returning" the flash loan.  
See [side-entrance.challenge.js](./test/side-entrance/side-entrance.challenge.js) and [SideEntranceAttack.sol](./contracts/attacker-contracts/SideEntranceAttack.sol).


## 5. The rewarder

As soon as a new snapshot is due in the rewarder pool, take out a flash loan of as many DVT tokens as you can and deposit them into the rewarder pool to trigger the snapshot and the reward distribution.
Afterwards, you can immediately withdraw the DVT tokens again and pay back the flash loan. All in one transaction.  
See [the-rewarder.challenge.js](./test/the-rewarder/the-rewarder.challenge.js) and [TheRewarderAttack.sol](./contracts/attacker-contracts/TheRewarderAttack.sol).


## 6. Selfie

Here we can just take out a flash loan of as many DVT tokens as possible and manually initiate a snapshot. This makes us eligible to perform a governance action, a malicious one,
which withdraws all funds from the pool, to be specific.  
See [selfie.challenge.js](./test/selfie/selfie.challenge.js) and [SelfieAttack.sol](./contracts/attacker-contracts/SelfieAttack.sol).


## 7. Compromised

Turns out that the strange server response contains the private keys for 2 of 3 "trusted" price oracle sources. Let's manipulate the DVNFT price to drain the exchange contract.  
See [compromised.challenge.js](./test/compromised/compromised.challenge.js)


## 8. Puppet

Because of the low liquidity of the DVT/ETH pair, we can easily manipulate the price and drain the DVT pool for a low (in comparison) ETH deposit.  
See [puppet.challenge.js](./test/puppet/puppet.challenge.js)



