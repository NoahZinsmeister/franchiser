// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IFranchiserEvents} from "./IFranchiserEvents.sol";
import {IFranchiserErrors} from "./IFranchiserErrors.sol";
import {IVotingToken} from "./IVotingToken.sol";

/// @title The interface for the Franchiser contract.
interface IFranchiser is IFranchiserEvents, IFranchiserErrors {
    /// @notice The `votingToken` of the contract.
    /// @return votingToken The `votingToken`.
    function votingToken() external returns (IVotingToken votingToken);

    /// @notice The current `beneficiary` of the contract.
    /// @return beneficiary The `beneficiary`.
    function beneficiary() external returns (address beneficiary);

    /// @notice Changes the `beneficiary` of the contract.
    /// @dev Can only be called by the `owner`.
    /// @param newBeneficiary The new `beneficiary`.
    function changeBeneficiary(address newBeneficiary) external;

    /// @notice Delegates the contract's balance of `votingToken` to `delegatee`.
    /// @dev Can only be called by the `beneficiary`.
    /// @param delegatee The address that will recieve voting power.
    function delegate(address delegatee) external;

    /// @notice Transfers the contract's balance of `votingToken` to `to`.
    /// @dev Can only be called by the `owner`.
    /// @param to The address that will recieve tokens.
    function recall(address to) external;
}
