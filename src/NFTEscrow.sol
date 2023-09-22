// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC721} from "@openzeppelin-contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";
import {INFTEscrow} from "./interface/INFTEscrow.sol";

contract NFTEscrow is ERC721Holder, INFTEscrow {
    /**
     * ========================================================= *
     *                         Mappings                          *
     * ========================================================= *
     */
    // Mapping to store borrower's tokencontract NFTs no in the pool
    mapping(address => mapping(address => uint256)) public userCollateralBalance;

    /**
     * ========================================================= *
     *                     Internal Function                     *
     * ========================================================= *
     */

    /**
     * @dev Deposits ERC721 collateral to escrow (this contract).
     * @notice Borrower deposits NFT collateral to this contract.
     * @param borrower_ The address of the borrower.
     * @param tokenContract_ The address of the ERC721 token contract.
     * @param tokenId_ The ID of the ERC721 token.
     */
    function _depositERC721Collateral(address borrower_, address tokenContract_, uint256 tokenId_) internal {
        IERC721 token = IERC721(tokenContract_);
        address owner = token.ownerOf(tokenId_);
        uint256 borrowerBalance = token.balanceOf(borrower_);
        if (owner != borrower_) {
            revert BorrowerIsNotOwnerOfNFT(owner, borrower_);
        }
        if (borrowerBalance == 0) {
            revert BorrowerDoNotHaveNFT(borrower_);
        }
        if (userCollateralBalance[borrower_][tokenContract_] > borrowerBalance) {
            revert NoMoreCollateralSlots(borrowerBalance, userCollateralBalance[borrower_][tokenContract_]);
        }

        bytes memory data =
            abi.encodeWithSignature("transferFrom(address,address,uint256)", borrower_, address(this), tokenId_);
        // Transfer the NFT to this contract
        (bool isTransferred,) = _call(tokenContract_, 0, data);
        if (isTransferred) {
            userCollateralBalance[borrower_][tokenContract_] += 1;
        } else {
            revert TransferFailed();
        }
    }

    /**
     * @dev Withdraws ERC721 collateral from escrow (this contract).
     * @notice Borrower withdraws NFT collateral from this contract.
     * @param borrower_ The address of the borrower.
     * @param tokenContract_ The address of the ERC721 token contract.
     * @param tokenId_ The ID of the ERC721 token.
     */
    function _withdrawERC721Collateral(address borrower_, address tokenContract_, uint256 tokenId_) internal {
        IERC721 token = IERC721(tokenContract_);

        if (msg.sender != borrower_) {
            revert OnlyBorrowerCanWithdrawNFT(msg.sender, borrower_);
        }
        if (token.ownerOf(tokenId_) != address(this)) {
            revert NFTNotUsedAsCollateral(tokenId_);
        }
        if (userCollateralBalance[borrower_][tokenContract_] == 0) {
            revert BorrowerHasNoNFTInTokenContract();
        }

        // Transfer the NFT from this contract back to the borrower
        bytes memory data =
            abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), borrower_, tokenId_);

        // Transfer the NFT to this contract
        (bool isTransferred,) = _call(tokenContract_, 0, data);
        if (isTransferred) {
            userCollateralBalance[borrower_][tokenContract_] -= 1;
        } else {
            revert TransferFailed();
        }
    }

    function _call(address to_, uint256 amount_, bytes memory data_) internal returns (bool, bytes memory) {
        if (to_ == address(0)) {
            revert NullAddressIsNotAllowedInLowLevelCall();
        }
        (bool success, bytes memory data) = payable(to_).call{value: amount_}(data_);
        return (success, data);
    }
}
