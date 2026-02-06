// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title MasterToken
 * @dev A comprehensive ERC20 implementation with role-based access control, 
 * burnable tokens, and permit functionality for gasless approvals.
 * 
 * 💡 REUSABILITY: Inherit this contract to create any project token.
 * 💡 CUSTOMIZATION: Override `_update` for custom logic (taxes, limits).
 */
contract MasterToken is ERC20, ERC20Burnable, ERC20Permit, AccessControl {
    // Role required to mint new tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Constructor that initializes the token and sets up admin roles.
     * @param name The name of the token (e.g., "MyToken").
     * @param symbol The symbol of the token (e.g., "MTK").
     * @param initialOwner Address receiving DEFAULT_ADMIN_ROLE and MINTER_ROLE.
     */
    constructor(string memory name, string memory symbol, address initialOwner) 
        ERC20(name, symbol) 
        ERC20Permit(name) 
    {
        // Grant admin rights to the initial owner (usually a deployer or multi-sig)
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        // Grant minting rights to the initial owner
        _grantRole(MINTER_ROLE, initialOwner);
    }

    /**
     * @dev Creates `amount` new tokens and assigns them to `to`.
     * 
     * 🔐 SECURITY: Protected by the `MINTER_ROLE`.
     * 🚀 USAGE: Call this from a backend script or a Presale contract.
     * 
     * @param to The target address that will receive the tokens.
     * @param amount The number of tokens to be minted (including decimals).
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
