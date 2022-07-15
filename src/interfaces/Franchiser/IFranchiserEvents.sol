// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {Franchiser} from "../../Franchiser.sol";

/// @title Events for the Franchiser contract.
interface IFranchiserEvents {
    /// @notice Emitted once per Franchiser.
    /// @param owner The `owner`.
    /// @param delegator The `delegator`.
    /// @param delegatee The `delegatee`.
    /// @param maximumSubDelegatees The `maximumSubDelegatees`.
    event Initialized(
        address indexed owner,
        address indexed delegator,
        address indexed delegatee,
        uint96 maximumSubDelegatees
    );

    /// @notice Emitted when a `subDelegatee` is activated.
    /// @param subDelegatee The `subDelegatee`.
    event SubDelegateeActivated(address indexed subDelegatee);

    /// @notice Emitted when a `subDelegatee` is deactivated.
    /// @param subDelegatee The `subDelegatee`.
    event SubDelegateeDeactivated(address indexed subDelegatee);
}
