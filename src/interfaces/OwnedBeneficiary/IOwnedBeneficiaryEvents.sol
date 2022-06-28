// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Events for the OwnedBeneficiary contract.
interface IOwnedBeneficiaryEvents {
    /// @notice Emitted once per OwnedBeneficiary, when a `beneficiary` is set.
    /// @param beneficiary The `beneficiary`.
    event Initialized(address indexed beneficiary);
}
