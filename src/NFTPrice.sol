// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC721} from "@openzeppelin-contracts/token/ERC721/ERC721.sol";
import {AurumOracle} from "./AurumOracle.sol";
import {INFTPrice} from "src/interface/INFTPrice.sol";

contract NFTPrice is INFTPrice {
    /**
     * ========================================================= *
     *                         Constants                         *
     * ========================================================= *
     */
    // Chainlink and custom price feed contract addresses for different NFTs
    address constant AURUMORACLE_PRICEFEED = 0xF3B3AEC4cB38CD46f086f88827EF5ab46aA84e17;
    address constant ETH_TO_USD_PRICEFEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    /**
     * ========================================================= *
     *                      Public Function                      *
     * ========================================================= *
     */

    /**
     * @dev See {INFTPrice-getNFTPrice}.
     */
    function getNFTPrice(address _tokenContract, uint256 tokenId) public view returns (uint256) {
        ERC721 nftContract = ERC721(_tokenContract);
        address owner = nftContract.ownerOf(tokenId);

        if(owner == address(0)) {
            revert("None");
        }
        return _getNFTPrice(_tokenContract);
    }

    /**
     * @dev See {INFTPrice-getEthToUsdPrice}.
     */
    function getEthToUsdPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ETH_TO_USD_PRICEFEED);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /**
     * ========================================================= *
     *                     Internal Function                     *
     * ========================================================= *
     */

    // Internal function to get the price from the price feed contract
    function _getNFTPrice(address _tokenContract) internal view returns (uint256) {
        AurumOracle priceFeed = AurumOracle(AURUMORACLE_PRICEFEED);
        (uint256 price) = priceFeed.getNFTFloorPrice(_tokenContract);
        return (price);
    }
}
