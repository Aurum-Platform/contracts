// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// sepolia contract 0x5e644C066f5695A55D48AA93FFa64dcDc056c23d
// https://sepolia.etherscan.io/address/0x5e644C066f5695A55D48AA93FFa64dcDc056c23d

import {IERC721} from "@openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin-contracts/utils/introspection/IERC165.sol";
import {NFTPrice} from "./NFTPrice.sol";
import {AurumAdmin} from "./AurumAdmin.sol";
import {NFTEscrow} from "./NFTEscrow.sol";
import {IAurumV2core} from "./interface/IAurumV2core.sol";

contract AurumV2core is AurumAdmin, NFTEscrow, NFTPrice, IAurumV2core {
    /**
     * ========================================================= *
     *                   Variables & Constants                   *
     * ========================================================= *
     */
    // Mapping to store deposits by user address
    mapping(address => Deposit[]) public deposits;
    // Mapping to store the number of deposits per user
    mapping(address => uint256) public userDepositNum;
    // Mapping to store loans by user address
    mapping(address => Loan[]) public loans;
    // Mapping to store the number of collaterals per user
    mapping(address => uint256) public userColleteralNum;

    // Constructor
    constructor(uint256 borrowInterestRate_, uint256 lendingInterestRate_, uint256 maxLoanToValue_) payable {
        borrowInterestRate = borrowInterestRate_;
        lendingInterestRate = lendingInterestRate_;
        maxLoanToValue = maxLoanToValue_;
    }

    // Fallback function to reject any incoming calls with invalid function signatures
    fallback() external payable {
        revert FunctionSignatureNotFound();
    }

    // Receive function to receive ETH
    receive() external payable {
        uint256 amount_ = msg.value;
        if (amount_ > MAX_DEPOSIT_AMOUNT_LIMIT) {
            revert DepositionLimitReached(amount_, MAX_DEPOSIT_AMOUNT_LIMIT);
        }
        totalSupply += msg.value;
    }

    /**
     * ========================================================= *
     *                     External Function                     *
     * ========================================================= *
     */

    /**
     * @dev See {IAurumV2core-depositToPool}.
     */
    function depositToPool() external payable {
        if (msg.value == 0) {
            revert ZeroValueError(msg.value);
        }

        // Create a new deposit with the given deposition details
        Deposit memory deposit = Deposit({lender: msg.sender, amount: msg.value, lastUpdateTimestamp: block.timestamp});

        (bool success,) = _call(address(this), deposit.amount, "");
        if (!success) {
            revert ValueTransferFailed(deposit.amount);
        }

        deposits[msg.sender].push(deposit);
        userDepositNum[msg.sender] += 1;

        // Emit the Deposition event
        emit Deposition(deposits[msg.sender].length - 1, msg.sender, msg.value);
    }

    /**
     * @dev See {IAurumV2core-withdrawFromPool}.
     */
    function withdrawFromPool(uint256 depositId_) external {
        // Get the deposit object from the deposits mapping for the user
        Deposit storage deposit = deposits[msg.sender][depositId_];

        if (deposit.amount == 0) {
            revert AmountIsAlreadyPaid(depositId_, msg.sender);
        }

        // uint256 interest = _calculateInterest(lendingInterestRate, deposit.lastUpdateTimestamp, block.timestamp);
        uint256 interest = 0;
        uint256 withdrawAmount = deposit.amount + interest;
        // Updating the time stanp as the variable name suggests
        deposit.lastUpdateTimestamp = block.timestamp;

        // Attempt to transfer the funds to the user
        (bool success,) = _call(msg.sender, withdrawAmount, "");
        if (!success) {
            revert ValueTransferFailed(withdrawAmount);
        }

        // Update the total supply and emit the Withdrawal event
        totalSupply -= withdrawAmount;
        emit Withdrawal(depositId_, msg.sender, withdrawAmount);

        // Remove the deposit from the deposits after the withdrawal
        delete deposits[msg.sender][depositId_];
    }

    /**
     * @dev See {IAurumV2core-borrow}.
     */
    function borrow(uint256 amount_, address tokenContract_, uint256 tokenId_, uint256 duration_) external payable {
        // Check if the amount is greater than zero
        if (amount_ == 0) {
            revert ZeroValueError(msg.value);
        }

        // Get the collateral value of the ERC721 token
        uint256 collateralValue = getCollateralValue(tokenContract_, tokenId_);

        // Calculate the borrowing power based on the collateral value and maxLoanToValue ratio
        uint256 borrowingPower = (collateralValue * maxLoanToValue) / 10000;

        // Check if the requested amount exceeds the borrowing power
        if (amount_ > borrowingPower) {
            revert AmountExceedsBorrowingPower(amount_, borrowingPower);
        }

        // Create a new Loan struct with the loan details
        Loan memory loan = Loan({
            borrower: msg.sender,
            tokenContract: tokenContract_,
            tokenId: tokenId_,
            amount: amount_,
            collateralValue: collateralValue,
            lastUpdateTimestamp: block.timestamp,
            duration: duration_,
            isActive: true
        });

        // Deposit the ERC721 collateral into this contract
        _depositERC721Collateral(msg.sender, loan.tokenContract, loan.tokenId);

        loans[msg.sender].push(loan);

        // Update the totalBorrowed and totalDepositedNFTs variables
        totalBorrowed += amount_;
        totalDepositedNFTs += 1;

        // Increment the user's collateral count
        userColleteralNum[msg.sender] += 1;

        // Transfer the borrowed amount to the borrower
        (bool success,) = _call(msg.sender, loan.amount, "");
        if (!success) {
            revert ValueTransferFailed(loan.amount);
        }

        // Emit the Borrow event
        emit Borrow(msg.sender, loans[msg.sender].length - 1, loan.amount, loan.duration);
    }

    /**
     * @dev See {IAurumV2core-repay}.
     */
    function repay(uint256 loanId_) external {
        // Retrieve the loan details from the loans mapping
        Loan storage loan = loans[msg.sender][loanId_];

        // Check if the loan duration has not expired
        if (loan.duration < block.timestamp) {
            revert DebtNotPaidInTime(loanId_, msg.sender, loan.duration);
        }

        // Check if the caller is the borrower
        if (msg.sender != loan.borrower) {
            revert OnlyOwnerCanRepayTheLoan(loanId_, msg.sender, loan.borrower);
        }

        // Check if the loan is still active
        if (!loan.isActive) {
            revert LoanIsAlreadyPaid(loanId_, msg.sender);
        }

        uint256 interest =
            _calculateInterest(borrowInterestRate, loan.lastUpdateTimestamp, block.timestamp, loan.amount);
        // Calculate the total amount to repay (loan amount + interest)
        uint256 amountToRepay = loan.amount + interest;
        // Updating the time stanp as the variable name suggests
        loan.lastUpdateTimestamp = block.timestamp;

        // Transfer the repayment amount to the contract
        (bool success,) = _call(msg.sender, amountToRepay, "");
        if (!success) {
            revert ValueTransferFailed(amountToRepay);
        }

        // Withdraw the ERC721 collateral from the contract
        _withdrawERC721Collateral(msg.sender, loan.tokenContract, loan.tokenId);

        // Update the totalBorrowed and totalDepositedNFTs variables
        totalBorrowed -= loan.amount;
        totalDepositedNFTs -= 1;

        // Delete the loan after the payment of debt
        delete loans[msg.sender][loanId_];

        // Emit the Repay event
        emit Repay(msg.sender, loanId_, loan.amount, interest);
    }

    /**
     * @dev Withdraw liquidated NFT
     * @notice Allows the borrower or lender to withdraw or liquidate an NFT used as collateral for a loan
     * @param borrowerAddress The address of the borrower
     * @param _loanId The ID of the loan
     */
    function withdrawLiquidatedNFT(address borrowerAddress, uint256 _loanId) external payable {
        Loan storage loan = loans[borrowerAddress][_loanId];
        // Liquidation requirement check
        require(loan.duration < block.timestamp, "Loan not liquidated yet");
        require(loan.isActive == true, "Debt has been repaid");
        require(loan.collateralValue == msg.value, "Incorrect payment amount");
        loan.isActive = false;

        // Transfer the borrowed amount to the borrower
        (bool success,) = _call(address(this), loan.collateralValue, "");
        if (!success) {
            revert ValueTransferFailed(loan.amount);
        }

        // Transfer the NFT from this contract back to the borrower
        bytes memory data =
            abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), msg.sender, loan.tokenId);

        // Transfer the NFT to this contract
        (bool isTransferred,) = _call(loan.tokenContract, 0, data);
        if (isTransferred) {
            userCollateralBalance[loan.borrower][loan.tokenContract] -= 1;
        } else {
            revert TransferFailed();
        }
    }

    /**
     * ========================================================= *
     *                      Public Function                      *
     * ========================================================= *
     */

    /**
     * @dev See {IAurumV2core-getCollateralValue}.
     */
    function getCollateralValue(address tokenContract_, uint256 tokenId_) public returns (uint256) {
        // Get the price of the ERC721 token
        uint256 price = getNFTPrice(tokenContract_, tokenId_);

        // Check if the token contract supports the ERC721Metadata interface
        if (IERC165(tokenContract_).supportsInterface(type(IERC721).interfaceId)) {
            return price;
        } else {
            revert UnsupportedTokenType(type(IERC165).interfaceId);
        }
    }

    /**
     * @dev Adds Aurum Client address to Aurum.
     */
    function setAurumClient(address aurumClientContract_) public onlyOwner {
        require(aurumClientContract_ != address(0), "Invalid Aurum Client address");
        require(aurumClientContract == aurumClientContract, "Aurum Client address already set");
        aurumClientContract = aurumClientContract_;
    }
}
