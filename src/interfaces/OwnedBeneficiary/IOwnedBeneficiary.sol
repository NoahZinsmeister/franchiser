// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IOwnedBeneficiaryErrors} from "./IOwnedBeneficiaryErrors.sol";
import {IOwnedBeneficiaryEvents} from "./IOwnedBeneficiaryEvents.sol";
import {IFranchiserImmutableState} from "../IFranchiserImmutableState.sol";

/// @title Interface for the OwnedBeneficiary contract.
interface IOwnedBeneficiary is
    IOwnedBeneficiaryErrors,
    IOwnedBeneficiaryEvents,
    IFranchiserImmutableState
{
    /// @notice The current `beneficiary` of the contract.
    /// @dev Cannot be immutable beacuse this contract is used via EIP-1167 clones.
    /// @return beneficiary The `beneficiary`.
    function beneficiary() external returns (address beneficiary);

    /// @notice Can be called once to set the contract's `beneficiary`.
    ///         Intended to be used in the context of
    /// @param owner The `owner`.
    /// @param beneficiary The `beneficiary`.
    function initialize(address owner, address beneficiary) external;

    /// @notice Delegates the contract's balance of `votingToken` to `delegatee`.
    /// @dev Can only be called by the `beneficiary`.
    /// @param delegatee The address that will receive voting power.
    function delegate(address delegatee) external;

    /// @notice Transfers the contract's balance of `votingToken` to `to`.
    /// @dev Can only be called by the `owner`.
    /// @param to The address that will receive tokens.
    function recall(address to) external;
}
