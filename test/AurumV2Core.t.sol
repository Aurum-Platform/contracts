// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Import the AurumV2core contract to be tested
import {AurumV2core} from "../src/AurumV2core.sol";

//Import the mock NFT contract for test
import {MockNFT} from "../src/mocks/ERC721Mock.sol";

// Import the Forge Standard Library's Test contract
import {Test} from "forge-std/Test.sol";

// Inherit from Test contract
contract AurumV2coreTest is Test {
    error FunctionSignatureNotFound();
    error DepositionLimitReached(uint256 amount_, uint256 maxDepositAmount_);
    error ZeroValueError(uint256 value_);
    error AmountIsAlreadyPaid(uint256 depositId_, address sender_);
    error AmountExceedsBorrowingPower(uint256 amount_, uint256 borrowingPower_);
    error DebtNotPaidInTime(uint256 loanId_, address sender_, uint256 duration_);
    error OnlyOwnerCanRepayTheLoan(uint256 loanId_, address sender_, address borrower_);
    error LoanIsAlreadyPaid(uint256 loanId_, address sender_);
    error IncorrectValueTransferred(uint256 amountToRepay_, uint256 transferredAmount_);
    error ValueTransferFailed(uint256 amount_);

    struct Deposit {
        uint256 amount;
        uint256 duration;
        uint256 lastUpdateTimestamp;
    }

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

    event Deposition(uint256 indexed depoId, address indexed lender, uint256 indexed amount);

    // Contract instance to be tested
    AurumV2core private aurum;
    // Mock NFT instance
    MockNFT private mockNFT;

    address private constant user = 0xd2B93E349EbA5FF8673Be42b30Fd7C17904E0401;

    // Deploy AurumV2core before each test case
    function setUp() public {
        uint256 borrowInterestRate = 1000; // Set an appropriate interest rate
        uint256 lendingInterestRate = 1000; // Set an appropriate interest rate
        uint256 maxLoanToValue = 5000; // Set an appropriate maximum loan-to-value ratio
        aurum = new AurumV2core(borrowInterestRate, lendingInterestRate, maxLoanToValue);
        mockNFT = new MockNFT();
        vm.deal(address(aurum), 10 ether);
        vm.deal(user, 1 ether);
    }

    fallback() external payable {}

    receive() external payable {}

    // Test initialization of AurumV2core contract
    function test_InitializeAurumV2coreVariable() public {
        // Assert that the contract is initialized correctly
        assertEq(aurum.borrowInterestRate(), 1000);
        assertEq(aurum.lendingInterestRate(), 1000);
        assertEq(aurum.maxLoanToValue(), 5000);
        assertEq(aurum.owner(), 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        assertEq(aurum.totalSupply(), 0);
        assertEq(aurum.totalBorrowed(), 0);
        assertEq(aurum.totalDepositedNFTs(), 0);
    }

    // Test depositToPool function
    function testFuzz_DepositToPool(uint256 amount) public {
        vm.assume(amount <= 0.01 ether);
        vm.assume(amount > 0 ether);

        // Initital ETH balance of aurum
        uint256 inititalBalance = address(aurum).balance;

        vm.expectEmit(address(aurum));
        emit Deposition(0, address(this), amount);

        // Perform the deposit
        aurum.depositToPool{value: amount}();

        // Final Balance of aurum
        uint256 finalBalance = address(aurum).balance;
        // Asserts the initial balance with final balance
        assertEq(inititalBalance, finalBalance - amount);

        (address lender, uint256 lendAmount, uint256 lastUpdatedTimestamp) = aurum.deposits(address(this), 0);
        // Assert that the deposit is recorded correctly
        assertEq(lender, address(this));
        assertEq(lendAmount, amount);
        assertEq(lastUpdatedTimestamp, block.timestamp);
        assertEq(aurum.userDepositNum(address(this)), 1);
    }

    function testFuzz_WithdrawFromPool(uint256 amount) public {
        vm.assume(amount <= 0.01 ether);
        vm.assume(amount > 0 ether);
        // uint256 amount = 1 ether / 1000; // Set an appropriate deposit amount

        aurum.depositToPool{value: amount}();
        aurum.withdrawFromPool(0);

        aurum.depositToPool{value: amount}();
        // Fast forwarding time to 1 days.
        skip(1 days);
        aurum.withdrawFromPool(1);

        aurum.depositToPool{value: amount}();
        // Fast forwarding time to 7 days.
        skip(7 days);
        aurum.withdrawFromPool(2);

        // Expecting revert if already withdrawn.
        vm.expectRevert(abi.encodeWithSelector(AmountIsAlreadyPaid.selector, 2, address(this)));
        aurum.withdrawFromPool(2);

        // Assert that the deposit is removed correctly after withdrawal
        // assertEq(aurum.deposits(address(this)).length, 0);
        assertEq(aurum.userDepositNum(address(this)), 3);
    }

    function test_revertUnitTesting() public {
        // bytes memory customError = abi.encodeWithSelector(FunctionSignatureNotFound.selector);
        // vm.mockCallRevert(
        //     address(aurum),
        //     1 ether,
        //     bytes4(abi.encodePacked("none")),
        //     customError
        // );
        // vm.expectRevert(customError);

        // aurum.someInvalidFunction{value: 1 ether}();

        // Revert test for zero value deposited.
        vm.expectRevert(abi.encodeWithSelector(ZeroValueError.selector, 0));
        aurum.depositToPool{value: 0}();

        uint256 amount = 1 ether;
        vm.expectRevert(abi.encodeWithSelector(ValueTransferFailed.selector, 1000000000000000000));
        aurum.depositToPool{value: amount}();

        // Create a new ERC721 token
        mockNFT.mint(0);

        mockNFT.approve(address(aurum), 0);

        // Should revert on 0 amount borrow
        vm.expectRevert(abi.encodeWithSelector(ZeroValueError.selector, 0));
        aurum.borrow{value: 0}(0, address(mockNFT), 0, 7 days);

        // Should revert when amount exceeds borrowing power amount borrow
        vm.expectRevert(abi.encodeWithSelector(AmountExceedsBorrowingPower.selector, 1e18, 5e14));
        aurum.borrow{value: amount}(amount, address(mockNFT), 0, 7 days);

        uint256 loanAmount = 1 ether / 10000;

        mockNFT.approve(address(aurum), 0);

        // Call the borrow function with valid inputs
        aurum.borrow{value: loanAmount}(loanAmount, address(mockNFT), 0, 7 days);

        // Fast forward time to simulate the passage of time
        skip(8 days);

        // Should revert when debt is not paid in time
        vm.expectRevert(
            abi.encodeWithSelector(DebtNotPaidInTime.selector, 0, 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496, 6.048e5)
        );
        aurum.repay(0);
    }

    // Test borrow function
    function test_Borrow() public {
        // Create a new ERC721 token
        mockNFT.mint(0);
        uint256 amount = 1 ether / 10000;

        mockNFT.approve(address(aurum), 0);

        // Call the borrow function with valid inputs
        aurum.borrow{value: amount}(amount, address(mockNFT), 0, 7 days);

        // Retrieve the loan details
        (
            address borrower,
            address tokenContract,
            uint256 tokenId,
            uint256 loanAmount,
            uint256 collateralValue,
            uint256 lastUpdateTimestamp,
            uint256 duration,
            bool isActive
        ) = aurum.loans(address(this), 0);

        // Assert that the loan was created successfully
        assertEq(borrower, address(this));
        assertEq(tokenContract, address(mockNFT));
        assertEq(tokenId, 0);
        assertEq(loanAmount, amount);
        assertEq(isActive, true);
        assertEq(mockNFT.ownerOf(0), address(aurum));
    }

    // Test repay function
    function test_Repay() public {
        // Create a new ERC721 token
        mockNFT.mint(0);
        uint256 amount = 1 ether / 10000;

        mockNFT.approve(address(aurum), 0);

        // Call the borrow function with valid inputs
        aurum.borrow{value: amount}(amount, address(mockNFT), 0, 7 days);

        // Fast forward time to simulate the passage of time
        skip(6 days);

        // Call the repay function with the correct amount
        aurum.repay(0);

        // Retrieve the loan details after repayment
        (
            address borrower,
            address tokenContract,
            uint256 tokenId,
            uint256 loanAmount,
            uint256 collateralValue,
            uint256 lastUpdateTimestamp,
            uint256 duration,
            bool isActive
        ) = aurum.loans(address(this), 0);

        // Assert that the loan was repaid and deactivated
        assertEq(isActive, false);
        // Add more assertions as needed
    }

    // Test setBorrowInterestRate function
    function testFuzz_SetBorrowInterestRate(uint256 newInterestRate_, uint256 amount_) public {
        vm.assume(newInterestRate_ > 0);
        vm.assume(amount_ <= 0.01 ether);
        vm.assume(amount_ > 0 ether);

        aurum.depositToPool{value: amount_}();
        aurum.setBorrowInterestRate(newInterestRate_);

        // Assert that the interest rate is set correctly
        assertEq(aurum.borrowInterestRate(), newInterestRate_);
    }

    // Test setMaxLoanToValue function
    function testFuzz_SetMaxLoanToValue(uint256 newLoanToValue_) public {
        vm.assume(newLoanToValue_ > 0);
        aurum.setLoanToValue(newLoanToValue_);

        // Assert that the loan-to-value ratio is set correctly
        assertEq(aurum.maxLoanToValue(), newLoanToValue_);
    }

    // Test getUtilization function
    function test_GetUtilization() public {
        uint256 duration = 7 days; // Set an appropriate duration
        uint256 amount = 1e16; // Set an appropriate deposit amount
        // Perform the deposit
        aurum.depositToPool{value: amount}();

        // Create a new ERC721 token
        mockNFT.mint(0);
        uint256 loanAmount = 1 ether / 10000;

        mockNFT.approve(address(aurum), 0);

        // Call the borrow function with valid inputs
        aurum.borrow{value: loanAmount}(loanAmount, address(mockNFT), 0, 7 days);

        // Get the utilization of the pool
        uint256 utilization = aurum.getUtilization();

        // Assert that the utilization is calculated correctly
        assertEq(utilization, (loanAmount * 10000) / aurum.totalSupply());
    }

    // Test liquidation of a loan and transfer of NFT
    function test_LiquidateLoanAndTransferNFT() public {
        // Create a new ERC721 token
        mockNFT.mint(0);
        uint256 amount = 1 ether / 10000;

        mockNFT.approve(address(aurum), 0);

        // Call the borrow function with valid inputs
        aurum.borrow{value: amount}(amount, address(mockNFT), 0, 7 days);

        // Fast forward time to simulate the passage of time
        skip(7 days);
        vm.prank(user);

        // Liquidate the loan and transfer NFT
        aurum.withdrawLiquidatedNFT{value: 1e15}(address(this), 0);

        // Assert that the loan is removed correctly after liquidation
        assertEq(mockNFT.ownerOf(0), user);
    }
}
