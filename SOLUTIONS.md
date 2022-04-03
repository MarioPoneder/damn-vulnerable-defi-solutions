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

Because of the low liquidity of the DVT/ETH pair (Uniswap v1), we can easily manipulate the price and drain the DVT pool for a low (in comparison) ETH deposit.  
See [puppet.challenge.js](./test/puppet/puppet.challenge.js)


## 9. Puppet v2

Same as previous challenge but with a DVT/WETH pair (Uniswap v2) instead.  
See [puppet-v2.challenge.js](./test/puppet-v2/puppet-v2.challenge.js)


## 10. Free rider

The NFT marketplace contract in this challenge has two major vulnerabilities. First, the improper of use of `msg.value` lets us buy many NFTs at once for the price of one.
Second, the marketplace transfers the ETH paid for an NFT to its owner, but AFTER transferring ownership to the new owner, i.e. you get your ETH back after buying an NFT.  
Therefore, we can complete the challenge by borrowing enough ETH for one NFT using an Uniswap flash swap, then drain all NFTs and ETH from the marketplace by simply "buying"
all NFTs at once and afterwards transfer the NFTs to the mysterious buyer.  
See [free-rider.challenge.js](./test/free-rider/free-rider.challenge.js) and [FreeRiderAttack.sol](./contracts/attacker-contracts/FreeRiderAttack.sol).


## 11. Backdoor

A Gnosis Safe wallet can be created by anyone for anyone, therefore we (the attacker) can create a wallet for each beneficiary of the registry.
Unfortunately for us, even though the wallet was created by the attacker, funds can only be moved by the specified owner (the beneficiary).
However, Gnosis built a little backdoor into their "safe" wallet which lets us call an arbitrary function using `delegatecall` (!!!) during wallet setup.
This way, we can simply execute the `approve` function of the token, which is rewarded by the registry, on behalf of the "safe" wallet such that the attacker can
simply withdraw them immediately afterwards.  
See [backdoor.challenge.js](./test/backdoor/backdoor.challenge.js) and [BackdoorAttack.sol](./contracts/attacker-contracts/BackdoorAttack.sol).


## 12. Climber

The timelock contract, which is the owner of the vault contract, has a major vulnerability which also endangers the vault.
The `execute` function of the timelock only checks if the executed operation is scheduled after executing it. This way, we can change the proposer role
of the timelock and schedule the operation during execution in order to pass the check.
Once the timelock is taken over, we can schedule & execute an operation which upgrades the vault contract to our attack contract und subsequently drains
all DVT tokens from the vault.  
See [climber.challenge.js](./test/climber/climber.challenge.js) and [ClimberAttack.sol](./contracts/attacker-contracts/ClimberAttack.sol).