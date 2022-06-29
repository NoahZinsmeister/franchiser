// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IOwnedDelegatorErrors} from "./IOwnedDelegatorErrors.sol";
import {IOwnedDelegatorEvents} from "./IOwnedDelegatorEvents.sol";
import {IFranchiserImmutableState} from "../IFranchiserImmutableState.sol";

/// @title Interface for the OwnedDelegator contract.
interface IOwnedDelegator is
    IOwnedDelegatorErrors,
    IOwnedDelegatorEvents,
    IFranchiserImmutableState
{
    /// @notice The `delegatee` of the contract.
    /// @dev Never changes after being set via intialize,
    ///      but is not immutable because this contract is used via EIP-1167 clones.
    /// @return delegatee The `delegatee`.
    function delegatee() external returns (address delegatee);

    /// @notice Can be called once to set the contract's `delegatee`.
    /// @param owner The `owner`.
    /// @param delegatee The `delegatee`.
    function initialize(address owner, address delegatee) external;

    /// @notice Transfers the contract's balance of `votingToken` to `to`.
    /// @dev Can only be called by the `owner`.
    /// @param to The address that will receive tokens.
    function recall(address to) external;
}
