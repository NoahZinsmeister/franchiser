// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Errors thrown by the OwnedBeneficiary contract.
interface IOwnedBeneficiaryErrors {
    /// @notice Thrown when attempting to initialize an OwnedBeneficiary contract with
    ///         a `beneficiary` address of 0.
    error ZeroBeneficiary();

    /// @notice Thrown when attempting to set the `beneficiary` more than once.
    error AlreadyInitialized();

    /// @notice Thrown when an address other than the `beneficiary` attempts to call a
    ///         function restricted to the `beneficiary`.
    /// @param caller The address that attempted the call.
    /// @param beneficiary The `beneficiary`.
    error NotBeneficiary(address caller, address beneficiary);
}
