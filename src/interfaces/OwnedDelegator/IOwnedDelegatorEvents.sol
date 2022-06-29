// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Events for the OwnedDelegator contract.
interface IOwnedDelegatorEvents {
    /// @notice Emitted once per OwnedDelegator.
    /// @param owner The `owner`.
    /// @param delegatee The `delegatee`.
    event Initialized(address indexed owner, address indexed delegatee);
}
