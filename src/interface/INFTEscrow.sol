// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title NFT Escrow Interface
 * @notice This interface defines the functions and error messages for an NFT Escrow contract.
 */
interface INFTEscrow {
    /**
     * @notice Error thrown when the borrower is not the owner of the NFT.
     * @param owner_ The address of the NFT owner.
     * @param borrower_ The address of the borrower.
     */
    error BorrowerIsNotOwnerOfNFT(address owner_, address borrower_);

    /**
     * @notice Error thrown when the borrower does not have the NFT.
     * @param borrower_ The address of the borrower.
     */
    error BorrowerDoNotHaveNFT(address borrower_);

    /**
     * @notice Error thrown when there are no more collateral slots available for the borrower.
     * @param borrowerBalance_ The balance of the borrower.
     * @param userCollateralSlots_ The number of collateral slots the user has.
     */
    error NoMoreCollateralSlots(uint256 borrowerBalance_, uint256 userCollateralSlots_);

    /**
     * @notice Error thrown when the borrower has no more collateral slots available.
     */
    error BorrowerHasNoMoreCollateralSlots();

    /**
     * @notice Error thrown when someone other than the borrower tries to withdraw the NFT.
     * @param sender_ The address of the sender.
     * @param borrower_ The address of the borrower.
     */
    error OnlyBorrowerCanWithdrawNFT(address sender_, address borrower_);

    /**
     * @notice Error thrown when the NFT is not used as collateral.
     * @param tokenId_ The ID of the NFT token.
     */
    error NFTNotUsedAsCollateral(uint256 tokenId_);

    /**
     * @notice Error thrown when the borrower has no NFT in the token contract.
     */
    error BorrowerHasNoNFTInTokenContract();

    /**
     * @notice Error thrown when an unsupported token type is encountered.
     * @param interfaceId_ The ID of the unsupported interface.
     */
    error UnsupportedTokenType(bytes4 interfaceId_);

    /**
     * @notice Error thrown when a token transfer fails.
     */
    error TransferFailed();

    /**
     * @notice Error thrown when a null address is not allowed in a low-level call.
     */
    error NullAddressIsNotAllowedInLowLevelCall();
}
