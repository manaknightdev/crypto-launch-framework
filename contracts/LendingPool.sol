// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LendingPool
 * @dev Generic smart contract for reputation-based lending pool
 * Supports multiple lending tiers with configurable deadlines and interest rates
 */
contract LendingPool is AccessControl, ReentrancyGuard {
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    // Stablecoin token contract (USDT, USDC, etc.)
    IERC20 public stablecoin;
    
    // Pool configuration
    struct PoolConfig {
        uint256 id;
        string name;
        uint256 requirement; // Minimum reputation score required
        uint256 loanAmount;  // Loan amount in stablecoin units
        uint256 tierLevel;
        uint256 loanDuration; // Loan duration in seconds (e.g., 30 days, 90 days)
        uint256 interestRate; // Annual interest rate (e.g., 10 = 10% APR)
        bool isActive;
    }
    
    // Loan structure
    struct Loan {
        uint256 id;
        address borrower;
        uint256 poolId;
        uint256 amount;
        uint256 tierLevel;
        uint256 borrowedAt;
        bool isRepaid;
        uint256 repaidAt;
    }
    
    // Mappings
    mapping(uint256 => PoolConfig) public pools;
    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) public borrowerLoans;
    
    // State variables
    uint256 public nextLoanId = 1;
    uint256 public totalLoans = 0;
    uint256 public totalRepaid = 0;
    uint256 public totalLent = 0;
    
    // Events
    event PoolConfigured(uint256 indexed poolId, string name, uint256 requirement, uint256 loanAmount);
    event LoanCreated(uint256 indexed loanId, address indexed borrower, uint256 poolId, uint256 amount);
    event LoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    constructor(address _stablecoinAddress, address initialAdmin) {
        require(_stablecoinAddress != address(0), "Invalid stablecoin address");
        stablecoin = IERC20(_stablecoinAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(VALIDATOR_ROLE, initialAdmin);
    }
    
    /**
     * @dev Configure a lending pool tier
     * Example: Pool 1 = 30 days, Pool 2 = 90 days, Pool 3 = 365 days
     */
    function configurePool(
        uint256 _poolId,
        string memory _name,
        uint256 _requirement,
        uint256 _loanAmount,
        uint256 _tierLevel,
        uint256 _loanDuration,
        uint256 _interestRate,
        bool _isActive
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pools[_poolId] = PoolConfig({
            id: _poolId,
            name: _name,
            requirement: _requirement,
            loanAmount: _loanAmount,
            tierLevel: _tierLevel,
            loanDuration: _loanDuration,
            interestRate: _interestRate,
            isActive: _isActive
        });
        
        emit PoolConfigured(_poolId, _name, _requirement, _loanAmount);
    }
    
    /**
     * @dev Authorize/revoke backend validator addresses
     */
    function setValidator(address _validator, bool _authorized) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_authorized) {
            _grantRole(VALIDATOR_ROLE, _validator);
        } else {
            _revokeRole(VALIDATOR_ROLE, _validator);
        }
    }
    
    /**
     * @dev Create a loan (called by backend after reputation validation)
     */
    function createLoan(
        address _borrower,
        uint256 _poolId,
        uint256 _reputationScore
    ) external onlyRole(VALIDATOR_ROLE) nonReentrant returns (uint256) {
        require(_borrower != address(0), "Invalid borrower address");
        
        PoolConfig memory pool = pools[_poolId];
        require(pool.isActive, "Pool not active");
        require(_reputationScore >= pool.requirement, "Insufficient reputation score");
        
        // Check if borrower has active loans
        uint256[] memory userLoans = borrowerLoans[_borrower];
        for (uint256 i = 0; i < userLoans.length; i++) {
            require(loans[userLoans[i]].isRepaid, "Borrower has active loan");
        }
        
        // Check contract has enough funds
        uint256 loanAmountWei = pool.loanAmount * 10**6; // Assuming 6 decimals
        require(stablecoin.balanceOf(address(this)) >= loanAmountWei, "Insufficient pool funds");
        
        // Create loan
        uint256 loanId = nextLoanId++;
        loans[loanId] = Loan({
            id: loanId,
            borrower: _borrower,
            poolId: _poolId,
            amount: pool.loanAmount,
            tierLevel: pool.tierLevel,
            borrowedAt: block.timestamp,
            isRepaid: false,
            repaidAt: 0
        });
        
        borrowerLoans[_borrower].push(loanId);
        totalLoans++;
        totalLent += pool.loanAmount;
        
        // Transfer stablecoin to borrower
        require(stablecoin.transfer(_borrower, loanAmountWei), "Transfer failed");
        
        emit LoanCreated(loanId, _borrower, _poolId, pool.loanAmount);
        
        return loanId;
    }
    
    /**
     * @dev Repay a loan (includes interest)
     */
    function repayLoan(uint256 _loanId) external nonReentrant {
        Loan storage loan = loans[_loanId];
        require(loan.id != 0, "Loan does not exist");
        require(loan.borrower == msg.sender, "Not the borrower");
        require(!loan.isRepaid, "Loan already repaid");
        
        uint256 interest = calculateInterest(_loanId);
        uint256 totalOwed = loan.amount + interest;
        uint256 repayAmountWei = totalOwed * 10**6;
        
        // Transfer stablecoin from borrower to contract
        require(stablecoin.transferFrom(msg.sender, address(this), repayAmountWei), "Transfer failed");
        
        // Mark loan as repaid
        loan.isRepaid = true;
        loan.repaidAt = block.timestamp;
        totalRepaid += loan.amount;
        
        emit LoanRepaid(_loanId, msg.sender, totalOwed);
    }
    
    /**
     * @dev Calculate interest for a loan
     * Interest = Principal * Rate * Time / (365 days * 100)
     */
    function calculateInterest(uint256 _loanId) public view returns (uint256) {
        Loan memory loan = loans[_loanId];
        if (loan.isRepaid) return 0;
        
        PoolConfig memory pool = pools[loan.poolId];
        uint256 timeElapsed = block.timestamp - loan.borrowedAt;
        
        uint256 interest = (loan.amount * pool.interestRate * timeElapsed) / (365 days * 100);
        return interest;
    }
    
    /**
     * @dev Check if a loan is defaulted (past deadline)
     */
    function isDefaulted(uint256 _loanId) public view returns (bool) {
        Loan memory loan = loans[_loanId];
        if (loan.id == 0 || loan.isRepaid) return false;
        
        PoolConfig memory pool = pools[loan.poolId];
        uint256 timeElapsed = block.timestamp - loan.borrowedAt;
        
        return timeElapsed > pool.loanDuration;
    }
    
    /**
     * @dev Liquidate a defaulted loan
     */
    function liquidate(uint256 _loanId) external onlyRole(VALIDATOR_ROLE) nonReentrant {
        require(isDefaulted(_loanId), "Loan not defaulted");
        
        Loan storage loan = loans[_loanId];
        loan.isRepaid = true;
        loan.repaidAt = block.timestamp;
        
        emit LoanRepaid(_loanId, loan.borrower, 0);
    }
    
    /**
     * @dev Deposit stablecoin to the pool
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 amountWei = _amount * 10**6;
        
        require(stablecoin.transferFrom(msg.sender, address(this), amountWei), "Transfer failed");
        
        emit FundsDeposited(msg.sender, _amount);
    }
    
    /**
     * @dev Withdraw funds from pool (admin only)
     */
    function withdraw(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 amountWei = _amount * 10**6;
        
        require(stablecoin.balanceOf(address(this)) >= amountWei, "Insufficient balance");
        require(stablecoin.transfer(msg.sender, amountWei), "Transfer failed");
        
        emit FundsWithdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Get pool information
     */
    function getPool(uint256 _poolId) external view returns (PoolConfig memory) {
        return pools[_poolId];
    }
    
    /**
     * @dev Get loan information
     */
    function getLoan(uint256 _loanId) external view returns (Loan memory) {
        return loans[_loanId];
    }
    
    /**
     * @dev Get borrower's loans
     */
    function getBorrowerLoans(address _borrower) external view returns (uint256[] memory) {
        return borrowerLoans[_borrower];
    }
    
    /**
     * @dev Get pool balance
     */
    function getPoolBalance() external view returns (uint256) {
        return stablecoin.balanceOf(address(this)) / 10**6;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
