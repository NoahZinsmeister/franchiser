// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IFranchiserImmutableState} from "./IFranchiserImmutableState.sol";
import {FranchiserFactory} from "../FranchiserFactory.sol";
import {Franchiser} from "../Franchiser.sol";

// import {IVotingToken} from "./IVotingToken.sol";

/// @title Interface for the FranchiserLens contract.
interface IFranchiserLens is IFranchiserImmutableState {
    /// @param delegator The `delegator`.
    /// @param delegatee The `delegatee`.
    /// @param franchiser The `franchiser`.
    struct Delegation {
        address delegator;
        address delegatee;
        Franchiser franchiser;
    }

    /// @param delegator The `delegator`.
    /// @param delegatee The `delegatee`.
    /// @param franchiser The `franchiser`.
    /// @param votes The voting power currently held in the `franchiser`.
    struct DelegationWithVotes {
        address delegator;
        address delegatee;
        Franchiser franchiser;
        uint256 votes;
    }

    /// @notice The deployed `franchiserFactory`.
    /// @return franchiserFactory The `franchiserFactory`.
    function franchiserFactory()
        external
        returns (FranchiserFactory franchiserFactory);

    /// @notice Gets the root delegation for any nested franchiser.
    /// @param franchiser The `franchiser`.
    /// @return delegation The root `delegation`.
    function getRootDelegation(Franchiser franchiser)
        external
        view
        returns (Delegation memory delegation);

    /// @notice Gets all vertical delegations starting from `franchiser`.
    /// @param franchiser The `franchiser`.
    /// @return delegations The chained `delegations`, starting from `franchiser`
    ///                     and ending at the root.
    function getVerticalDelegations(Franchiser franchiser)
        external
        view
        returns (Delegation[] memory delegations);

    /// @notice Gets all horizontal delegations of `franchiser`.
    /// @param franchiser The `franchiser`.
    /// @return delegations The descendant `delegations`.
    function getHorizontalDelegations(Franchiser franchiser)
        external
        view
        returns (Delegation[] memory delegations);

    /// @notice Gets the entire delegation tree containing the `franchiser`.
    /// @param franchiser The `franchiser`.
    /// @return delegationsWithVotes The `delegationsWithVotes`.
    function getAllDelegations(Franchiser franchiser)
        external
        view
        returns (DelegationWithVotes[][] memory delegationsWithVotes);
}
