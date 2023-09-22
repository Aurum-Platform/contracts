// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("Test NFT", "TNFT") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
}
