// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Errors thrown by the OwnedDelegator contract.
interface IOwnedDelegatorErrors {
    /// @notice Thrown when an address other than the `delegatee` attempts to call a
    ///         function restricted to the `delegatee`.
    /// @param caller The address that attempted the call.
    /// @param delegatee The `delegatee`.
    error NotDelegatee(address caller, address delegatee);

    /// @notice Thrown when attempting to initialize an OwnedDelegator contract with
    ///         a `delegatee` address of 0.
    error NoDelegatee();

    /// @notice Thrown when attempting to set the `delegatee` more than once.
    error AlreadyInitialized();
}
