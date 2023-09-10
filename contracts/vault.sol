// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable//utils/math/MathUpgradeable.sol";

contract CoreVault is Initializable, AccessControlUpgradeable {
    // -- Vault DATA --
    struct Collateral {
        uint256 TotalNormalisedDebt; // Total Normalised Debt
        uint256 rate; // Accumulated Rates
        uint256 price; // Price with Safety Margin
        uint256 debtCeiling; // Debt Ceiling
        uint256 debtFloor; // Debt Floor
    }

    struct Vault {
        uint256 lockedCollateral; // Locked Collateral in the system
        uint256 normalisedDebt; // Normalised Debt is a value that when you multiply by the correct rate gives the up-to-date, current stablecoin debt.
        VaultStateEnum vaultState;
    }

    struct List {
        uint prev;
        uint next;
    }

    uint256 public debt; // sum of all ngnx issued
    uint256 public live; // Active Flag
    uint vaultId; // auto incremental

    Vault[] vault; // list of vaults
    mapping(bytes32 => Collateral) public collateralMapping; // collateral name => collateral data
    mapping(uint => Vault) public vaultMapping; // vault ID => vault data
    mapping(uint => address) public ownerMapping; // vault ID => Owner
    mapping(address => uint) public firstVault; // Owner => First VaultId
    mapping(address => uint) public lastVault; // Owner => Last VaultId
    mapping(uint => List) public list; // VaultID => Prev & Next VaultID (double linked list)
    mapping(address => uint256) public availableNGNx; // owner => available ngnx balance -- waiting to be minted
    mapping(address => uint256) public unlockedCollateral; // owner => collateral balance -- unlocked collateral, not tied to a vault yet

    // -- ERRORS --
    error NotLive(string error);
    error ZeroAddress(string error);

    // -- EVENTS --
    event VaultCreated(uint vaultId, address indexed owner);
    event CollateralAdded(bytes32 collateralName);

    // - Vault type --
    enum VaultStateEnum {
        Idle, // Vault has just been created and users can deposit tokens into vault
        Active, // Vault has locked collaterals - users has minted NGNx
        Inactive // Vault has no locked collateral
    }

    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        live = 1;
    }

    // modifier
    modifier isLive() {
        if (live != 1) {
            revert NotLive("CoreVault/not-live");
        }
        _;
    }

    // -- ADMIN --

    function cage() external onlyRole(DEFAULT_ADMIN_ROLE) {
        live = 0;
    }

    function createCollateralType(
        bytes32 collateralName,
        uint256 rate,
        uint256 price,
        uint256 debtCeiling,
        uint256 debtFloor
    ) external isLive onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        Collateral storage _collateral = collateralMapping[collateralName];

        _collateral.rate = rate;
        _collateral.price = price;
        _collateral.debtCeiling = debtCeiling;
        _collateral.debtFloor = debtFloor;

        emit CollateralAdded(collateralName);
        return true;
    }

    function createVault(address owner) external isLive returns (uint) {
        if (owner == address(0)) {
            revert ZeroAddress("CoreVault/owner address is zero ");
        }
        vaultId += 1;

        Vault storage _vault = vaultMapping[vaultId];

        _vault.lockedCollateral = 0;
        _vault.normalisedDebt = 0;
        _vault.vaultState = VaultStateEnum.Idle;

        ownerMapping[vaultId] = owner;

        // add new vault to double linked list and pointers
        if (firstVault[owner] == 0) {
            firstVault[owner] = vaultId;
        }
        if (lastVault[owner] != 0) {
            list[vaultId].prev = lastVault[owner];
            list[lastVault[owner]].next = vaultId;
        }

        lastVault[owner] = vaultId;

        vault.push(_vault);

        emit VaultCreated(vaultId, owner);
        return vaultId;
    }
}
