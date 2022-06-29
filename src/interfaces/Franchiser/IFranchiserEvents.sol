// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {SubFranchiser} from "../../SubFranchiser.sol";

/// @title Events for the Franchiser contract.
interface IFranchiserEvents {
    /// @notice Emitted when a `subDelegatee` is activated.
    /// @param subDelegatee The `subDelegatee`.
    /// @param subFranchiser The SubFranchiser associated with the `subDelegatee`.
    event SubDelegateeActivated(
        address subDelegatee,
        SubFranchiser subFranchiser
    );

    /// @notice Emitted when a `subDelegatee` is deactivated.
    /// @param subDelegatee The `subDelegatee`.
    /// @param subFranchiser The SubFranchiser associated with the `subDelegatee`.
    event SubDelegateeDeactivated(
        address subDelegatee,
        SubFranchiser subFranchiser
    );
}
