// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TokenDistributor
 * @dev Generic vesting contract for token distribution across multiple categories
 * Supports cliff periods and linear vesting schedules
 */
contract TokenDistributor is Ownable, ReentrancyGuard {
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 startTime;
        uint256 cliffDuration;  // Time before vesting starts (e.g., 12 months)
        uint256 vestDuration;   // Total vesting period (e.g., 48 months)
        bool initialized;
    }

    IERC20 public immutable token;

    // Generic categories - customize for your project
    enum Category { COMMUNITY, ECOSYSTEM, STRATEGIC, COUNCIL, TEAM }

    mapping(Category => VestingSchedule) public categories;
    mapping(Category => address) public beneficiaries;

    event TokensClaimed(Category indexed category, address indexed beneficiary, uint256 amount);
    event BeneficiaryUpdated(Category indexed category, address indexed oldAddress, address indexed newAddress);
    event CategorySetup(Category indexed category, uint256 amount, uint256 cliffDuration, uint256 vestDuration);

    constructor(address _token, address initialOwner) Ownable(initialOwner) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    /**
     * @dev Initialize a vesting schedule for a category
     * @param _category Category enum (COMMUNITY, ECOSYSTEM, etc.)
     * @param _beneficiary Wallet address that can claim tokens (use multi-sig for mainnet)
     * @param _amount Total tokens allocated to this category
     * @param _startTime Unix timestamp when vesting starts
     * @param _cliffDuration Cliff period in seconds (e.g., 365 days)
     * @param _vestDuration Total vesting duration in seconds (e.g., 1460 days = 4 years)
     */
    function setupCategory(
        Category _category,
        address _beneficiary,
        uint256 _amount,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _vestDuration
    ) external onlyOwner {
        require(!categories[_category].initialized, "Category already setup");
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_amount > 0, "Amount must be greater than 0");

        categories[_category] = VestingSchedule({
            totalAmount: _amount,
            amountClaimed: 0,
            startTime: _startTime,
            cliffDuration: _cliffDuration,
            vestDuration: _vestDuration,
            initialized: true
        });
        beneficiaries[_category] = _beneficiary;
        
        emit CategorySetup(_category, _amount, _cliffDuration, _vestDuration);
        emit BeneficiaryUpdated(_category, address(0), _beneficiary);
    }

    /**
     * @dev Claim available tokens for a specific category
     * Can be called by anyone, but tokens go to the beneficiary
     */
    function claim(Category _category) external nonReentrant {
        VestingSchedule storage schedule = categories[_category];
        require(schedule.initialized, "Vesting not initialized");
        
        uint256 claimable = calculateClaimable(_category);
        require(claimable > 0, "Nothing to claim yet");

        schedule.amountClaimed += claimable;
        require(token.transfer(beneficiaries[_category], claimable), "Transfer failed");

        emit TokensClaimed(_category, beneficiaries[_category], claimable);
    }

    /**
     * @dev Calculate how many tokens can be claimed now
     * Formula: Linear vesting after cliff period
     */
    function calculateClaimable(Category _category) public view returns (uint256) {
        VestingSchedule storage schedule = categories[_category];
        if (!schedule.initialized) return 0;

        // Before cliff period
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }

        // After full vesting period
        if (block.timestamp >= schedule.startTime + schedule.cliffDuration + schedule.vestDuration) {
            return schedule.totalAmount - schedule.amountClaimed;
        }

        // During vesting period (linear)
        uint256 timeElapsed = block.timestamp - (schedule.startTime + schedule.cliffDuration);
        uint256 totalVested = (schedule.totalAmount * timeElapsed) / schedule.vestDuration;
        
        if (totalVested <= schedule.amountClaimed) return 0;
        
        return totalVested - schedule.amountClaimed;
    }

    /**
     * @dev Update beneficiary address (e.g., if wallet compromised)
     * Use multi-sig for this on mainnet!
     */
    function updateBeneficiary(Category _category, address _newBeneficiary) external onlyOwner {
        require(_newBeneficiary != address(0), "Invalid address");
        emit BeneficiaryUpdated(_category, beneficiaries[_category], _newBeneficiary);
        beneficiaries[_category] = _newBeneficiary;
    }

    /**
     * @dev Get vesting info for a category
     */
    function getVestingInfo(Category _category) external view returns (
        uint256 totalAmount,
        uint256 amountClaimed,
        uint256 claimable,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestDuration,
        address beneficiary
    ) {
        VestingSchedule storage schedule = categories[_category];
        return (
            schedule.totalAmount,
            schedule.amountClaimed,
            calculateClaimable(_category),
            schedule.startTime,
            schedule.cliffDuration,
            schedule.vestDuration,
            beneficiaries[_category]
        );
    }
}
