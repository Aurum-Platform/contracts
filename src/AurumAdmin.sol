// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {IAurumAdmin} from "./interface/IAurumAdmin.sol";

contract AurumAdmin is IAurumAdmin, Ownable {
    /**
     * ========================================================= *
     *                   Variables & Constants                   *
     * ========================================================= *
     */

    uint256 internal constant SECONDS_PER_YEAR = 356 days;
    // maximum amount user can deposit
    uint256 internal constant MAX_DEPOSIT_AMOUNT_LIMIT = 1e16;
    // borrowing interest rate in basis points
    uint256 public borrowInterestRate;
    // lending interest rate based on utilization
    uint256 public lendingInterestRate;
    // max loan to value ratio
    uint256 public maxLoanToValue;
    // Total amount in contract
    uint256 public totalSupply;
    // Total Borrowed amount by users
    uint256 public totalBorrowed;
    // Total deposited NFTs
    uint256 public totalDepositedNFTs;

    /**
     * ========================================================= *
     *                     External Function                     *
     * ========================================================= *
     */

    /**
     * @dev See {IAurumAdmin-getUtillization}.
     */
    function getUtilization() external view returns (uint256) {
        return (totalSupply == 0 && totalBorrowed == 0) ? 0 : (totalBorrowed * 10000) / totalSupply;
    }

    /**
     * ========================================================= *
     *                      Public Function                      *
     * ========================================================= *
     */

    /**
     * @dev See {IAurumAdmin-setBorrowInterestRate}.
     */
    function setBorrowInterestRate(uint256 borrowInterestRate_) public onlyOwner {
        borrowInterestRate = borrowInterestRate_;
        // lending interest rate based on uttilization of pool in basis point
        lendingInterestRate = borrowInterestRate_ * (totalBorrowed / totalSupply);
    }

    /**
     * @dev See {IAurumAdmin-setLoanToValue}.
     */
    function setLoanToValue(uint256 maxLoanToValue_) public onlyOwner {
        maxLoanToValue = maxLoanToValue_;
    }

    /**
     * ========================================================= *
     *                     Internal Function                     *
     * ========================================================= *
     */

    /**
     * @dev Calculates interest amount every 15 seconds (average block time).
     * @param interestRate_ Amount of funds to calculate interest.
     * @param lastUpdateTimestamp_ last update timestamp for interest calculation.
     * @param currentTimestamp_ current time stamp at the time of calculation.
     * @notice This function leverages (1+n)^x = 1 + nx + n(n-1)x^2/2! + ...
     * @custom:example | C = P(1+x)^n => (interest) C-P = pnx + pn(n-1)x^2/2 + pn(n-1)(n-2)x^3/6 (or secondTerm * x / 3)
     * @custom:example | n = 0; C-P = 0 and n = 1; C-P = px
     */
    function _calculateInterest(
        uint256 interestRate_,
        uint256 lastUpdateTimestamp_,
        uint256 currentTimestamp_,
        uint256 pricncipalAmpunt_
    ) internal pure returns (uint256) {
        uint256 exp = currentTimestamp_ - lastUpdateTimestamp_ / 15;

        if (exp == 0) {
            return 0;
        }
        uint256 ratePerSeconds = ((interestRate_ * 1e16) / 365 days) * 15;

        uint256 basePowerTwo = ratePerSeconds * ratePerSeconds;
        uint256 basePowerThree = basePowerTwo * ratePerSeconds;

        uint256 expMinusOne = exp - 1;
        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

        uint256 firstTerm = (exp * ratePerSeconds) / 1e18;
        uint256 secondTerm = ((exp * expMinusOne * basePowerTwo) / 2) / 1e36;
        uint256 thirdTerm = ((exp * expMinusOne * expMinusTwo * basePowerThree) / 6) / 1e54;

        return pricncipalAmpunt_ * (firstTerm + secondTerm + thirdTerm);
    }
}
