// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IAurumAdmin
 * @dev Interface for the Aurum protocol's administration contract.
 */
interface IAurumAdmin {
    /**
     * @dev Sets the borrow interest rate based on the pool's utilization.
     * @notice The borrow interest rate is adjusted dynamically based on the pool's utilization to incentivize or disincentivize borrowing.
     * @param borrowInterestRate_ The borrow interest rate set by the protocol's governance.
     */
    function setBorrowInterestRate(uint256 borrowInterestRate_) external;

    /**
     * @dev Sets the loan-to-value (LTV) ratio for over-collateralization of NFTs.
     * @notice The loan-to-value ratio determines the maximum amount of a loan that can be borrowed against the value of NFT collateral.
     * @param maxLoanToValue_ Maximum loan-to-value ratio of NFTs set by the protocol's governance.
     */
    function setLoanToValue(uint256 maxLoanToValue_) external;
}
