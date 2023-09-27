// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title NFT Price Interface
 * @notice This interface provides functions to get the price of NFTs and ETH to USD conversion rate.
 */
interface INFTPrice {

    /**
     * @notice Get the price of an NFT.
     * @dev Returns the price of the NFT denoted by the given token contract address and token ID.
     * @param _tokenContract The address of the ERC-721 token contract.
     * @param tokenId The ID of the NFT within the token contract.
     * @return The price of the NFT in wei.
     */
    function getNFTPrice(address _tokenContract, uint256 tokenId) external returns (uint256);

    /**
     * @notice Get the ETH to USD price.
     * @dev Returns the current ETH to USD conversion rate.
     * @return The ETH to USD price in USD cents.
     */
    function getEthToUsdPrice() external view returns (uint256);
}