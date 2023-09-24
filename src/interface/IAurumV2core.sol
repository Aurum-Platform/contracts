// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IAurumV2core
 * @dev Interface for the AurumV2core contract, which manages deposits and loans with ERC721 collateral.
 */
interface IAurumV2core {
    // Error declarations for different scenarios

    /**
     * @notice Error: Function Signature Not Found
     * @dev Used when trying to call a function that does not exist in the contract.
     */
    error FunctionSignatureNotFound();

    /**
     * @notice Error: Deposition Limit Reached
     * @param amount_ The amount being deposited.
     * @param maxDepositAmount_ The maximum deposit amount allowed.
     * @dev Used when a deposit exceeds the maximum allowed deposit amount.
     */
    error DepositionLimitReached(uint256 amount_, uint256 maxDepositAmount_);

    /**
     * @notice Error: Zero Value Error
     * @param value_ The value that resulted in the error.
     * @dev Used when a value should be greater than zero, but it's provided as zero.
     */
    error ZeroValueError(uint256 value_);

    /**
     * @notice Error: Amount Is Already Paid
     * @param depositId_ The ID of the deposit that was already paid.
     * @param sender_ The address that sent the payment.
     * @dev Used when trying to pay an amount that has already been paid for a specific deposit.
     */
    error AmountIsAlreadyPaid(uint256 depositId_, address sender_);

    /**
     * @notice Error: Amount Exceeds Borrowing Power
     * @param amount_ The amount being borrowed.
     * @param borrowingPower_ The maximum borrowing power available.
     * @dev Used when the amount being borrowed exceeds the user's borrowing power.
     */
    error AmountExceedsBorrowingPower(uint256 amount_, uint256 borrowingPower_);

    /**
     * @notice Error: Debt Not Paid In Time
     * @param loanId_ The ID of the loan for which the debt was not paid in time.
     * @param sender_ The address that failed to pay the debt in time.
     * @param duration_ The duration within which the debt should have been paid.
     * @dev Used when a loan's debt is not paid within the specified duration and the NFT gets liquidated.
     */
    error DebtNotPaidInTime(uint256 loanId_, address sender_, uint256 duration_);

    /**
     * @notice Error: Only Owner Can Repay The Loan
     * @param loanId_ The ID of the loan being repaid.
     * @param sender_ The address trying to repay the loan.
     * @param borrower_ The address of the borrower who should be the one repaying the loan.
     * @dev Used when someone other than the borrower tries to repay the loan.
     */
    error OnlyOwnerCanRepayTheLoan(uint256 loanId_, address sender_, address borrower_);

    /**
     * @notice Error: Loan Is Already Paid
     * @param loanId_ The ID of the loan that was already paid.
     * @param sender_ The address that tried to pay the loan.
     * @dev Used when trying to pay a loan that has already been fully repaid.
     */
    error LoanIsAlreadyPaid(uint256 loanId_, address sender_);

    /**
     * @notice Error: Incorrect Value Transferred
     * @param amountToRepay_ The amount that should have been transferred as part of repayment.
     * @param transferredAmount_ The amount that was actually transferred in the repayment.
     * @dev Used when the amount transferred during loan repayment is not the expected amount.
     */
    error IncorrectValueTransferred(uint256 amountToRepay_, uint256 transferredAmount_);

    /**
     * @notice Error: Value Transfer Failed
     * @param amount_ The amount that failed to be transferred.
     * @dev Used when a value transfer operation fails.
     */
    error ValueTransferFailed(uint256 amount_);

    /**
     * @notice Struct to store deposit details
     * @dev This struct holds information about a deposit made by a lender.
     * @param amount The amount of the deposit.
     * @param duration The duration of the deposit in seconds.
     * @param lastUpdateTimestamp The timestamp of the last update made to the deposit.
     */
    struct Deposit {
        address lender;
        uint256 amount;
        uint256 lastUpdateTimestamp;
    }

    /**
     * @notice Struct to store loan details
     * @dev This struct holds information about a loan taken by a borrower.
     * @param borrower The address of the borrower.
     * @param tokenContract The address of the ERC-721 token contract used as collateral.
     * @param tokenId The unique identifier of the token used as collateral.
     * @param amount The amount of the loan.
     * @param collateralValue The value of the collateral in the loan.
     * @param lastUpdateTimestamp The timestamp of the last update made to the loan.
     * @param duration The duration of the loan in seconds.
     * @param isActive Indicates whether the loan is active (true) or repaid (false).
     */
    struct Loan {
        address borrower;
        address tokenContract;
        uint256 tokenId;
        uint256 amount;
        uint256 collateralValue;
        uint256 lastUpdateTimestamp;
        uint256 duration;
        bool isActive;
    }

    /**
     * @dev Emitted when a lender makes a new deposit.
     * @param depoId The unique identifier for the deposit.
     * @param lender The address of the lender making the deposit.
     * @param amount The amount of the deposit.
     */
    event Deposition(uint256 indexed depoId, address indexed lender, uint256 indexed amount);

    /**
     * @dev Emitted when a lender withdraws their deposit.
     * @param depoId The unique identifier for the deposit.
     * @param lender The address of the lender withdrawing the deposit.
     * @param amount The amount being withdrawn from the deposit.
     */
    event Withdrawal(uint256 indexed depoId, address indexed lender, uint256 indexed amount);

    /**
     * @dev Emitted when a borrower takes a new loan.
     * @param borrower The address of the borrower taking the loan.
     * @param loanId The unique identifier for the loan.
     * @param amount The amount of the loan.
     * @param duration The duration of the loan in seconds.
     */
    event Borrow(address indexed borrower, uint256 indexed loanId, uint256 indexed amount, uint256 duration);

    /**
     * @dev Emitted when a borrower repays their loan.
     * @param borrower The address of the borrower repaying the loan.
     * @param loanId The unique identifier for the loan being repaid.
     * @param amount The amount being repaid on the loan.
     * @param interest The interest amount being paid on the loan.
     */
    event Repay(address indexed borrower, uint256 indexed loanId, uint256 indexed amount, uint256 interest);

    /**
     * @dev Deposit ETH into the pool.
     */
    function depositToPool() external payable;

    /**
     * @dev Withdraw deposit from pool.
     * @param depositId_ Id of the deposit to be withdrawn.
     */
    function withdrawFromPool(uint256 depositId_) external;

    /**
     * @dev Borrow funds by providing ERC721 collateral.
     * @param amount_ Amount of funds to borrow.
     * @param tokenContract_ Address of the token contract used as collateral.
     * @param tokenId_ Id of the token used as collateral.
     * @param duration_ Duration of the loan in seconds.
     */
    function borrow(uint256 amount_, address tokenContract_, uint256 tokenId_, uint256 duration_) external payable;

    /**
     * @dev Repay the loan.
     * @param loanId_ Id of the loan to be repaid.
     */
    function repay(uint256 loanId_) external;

    /**
     * @notice Calculates collateral value of a ERC721 token based on its price.
     * @param tokenContract_ Address of the ERC721 token contract.
     * @param tokenId_ Id of the ERC721 token.
     * @return Collateral value of the token.
     */
    function getCollateralValue(address tokenContract_, uint256 tokenId_) external returns (uint256);

    // View Functions

    /**
     * @notice Get the number of deposits made by a user.
     * @param user Address of the user.
     * @return Number of deposits made by the user.
     */
    function userDepositNum(address user) external view returns (uint256);

    /**
     * @notice Get the number of ERC721 tokens used as collateral by a user.
     * @param user Address of the user.
     * @return Number of ERC721 tokens used as collateral by the user.
     */
    function userColleteralNum(address user) external view returns (uint256);
}
