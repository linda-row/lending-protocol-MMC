// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract NGNX is AccessControl, ERC20, ERC20Permit {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // --- ERC20 Data ---
    string public constant version = "1";

    constructor()
        ERC20("NGNX Stablecoin", "NGNX")
        ERC20Permit("NGNX Stablecoin")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev sets a minter role
     * @param account address for the minter role
     */
    function setMinterRole(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _grantRole(MINTER_ROLE, account);
    }

    /**
     * @dev Mints a new token
     * @param account address to send the minted tokens to
     * @param amount amount of tokens to mint
     */
    function mint(address account, uint amount) external returns (bool) {
        require(hasRole(MINTER_ROLE, account));
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Burns a  token
     * @param account address to burn tokens from
     * @param amount amount of tokens to burn
     */
    function burn(address account, uint amount) external returns (bool) {
        if (
            account != msg.sender &&
            allowance(msg.sender, account) != type(uint).max
        ) {
            require(
                allowance(msg.sender, account) >= amount,
                "NGNx/insufficient-allowance"
            );
            decreaseAllowance(account, amount);
        }
        _burn(account, amount);
        return true;
    }

    function permitToken(
        address owner,
        address spender,
        uint256 value,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        permit(owner, spender, value, expiry, v, r, s);
    }
}
