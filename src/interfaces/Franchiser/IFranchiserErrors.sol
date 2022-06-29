// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {SubFranchiser} from "../../SubFranchiser.sol";

/// @title Errors thrown by the Franchiser contract.
interface IFranchiserErrors {
    /// @notice Thrown when attempting to add too many `subDelegatees`.
    /// @param maximumActiveSubDelegatees The maximum (and current) number of `subDelegatees`.
    error CannotExceedActiveSubDelegateesMaximum(
        uint256 maximumActiveSubDelegatees
    );

    /// @notice Thrown when the `subDelegatee` being added is already active.
    /// @param subDelegatee The `subDelegatee` being added.
    error SubDelegateeAlreadyActive(address subDelegatee);

    /// @notice Thrown when the `subDelegatee` being removed is not active.
    /// @param subDelegatee The `subDelegatee` being removed.
    error SubDelegateeNotActive(address subDelegatee);
}
