// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract Pausable {
    error Paused();

    uint256 internal constant FALSE = 1;
    uint256 internal constant TRUE = 2;

    uint256 public status; // Active status

    constructor() {
        status = TRUE;
    }

    modifier whenNotPaused() {
        if (status == FALSE) revert Paused();
        _;
    }

    function unpause() external virtual {
        status = TRUE;
    }

    function pause() external virtual {
        status = FALSE;
    }
}
