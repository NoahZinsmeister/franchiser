// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IFranchiserErrors} from "./IFranchiserErrors.sol";
import {IFranchiserEvents} from "./IFranchiserEvents.sol";
import {IOwnedDelegator} from "../OwnedDelegator/IOwnedDelegator.sol";
import {Franchiser} from "../../Franchiser.sol";

/// @title Interface for the Franchiser contract.
interface IFranchiser is IFranchiserErrors, IFranchiserEvents, IOwnedDelegator {
    /// @notice The implementation contract used to clone Franchiser contracts.
    /// @dev Used as part of an EIP-1167 proxy minimal proxy setup.
    /// @return franchiserImplementation The Franchiser implementation contract.
    function franchiserImplementation()
        external
        view
        returns (Franchiser franchiserImplementation);

    /// @notice The maximum number of `subDelegatee` addresses that the contract can have at any one time.
    /// @return maximumSubDelegatees The maximum number of `subDelegatee` addresses.
    function maximumSubDelegatees()
        external
        returns (uint256 maximumSubDelegatees);

    /// @notice The list of current `subDelegatee` addresses.
    /// @return subDelegatees The current `subDelegatee` addresses.
    function subDelegatees() external returns (address[] memory subDelegatees);

    /// @notice Can be called once to set the contract's `delegatee` and `maximumActiveSubDelegatees`.
    /// @param owner The `owner`.
    /// @param delegatee The `delegatee`.
    /// @param maximumActiveSubDelegatees The maximum number of `subDelegatee` addresses.
    function initialize(
        address owner,
        address delegatee,
        uint256 maximumActiveSubDelegatees
    ) external;

    /// @notice Looks up the Franchiser associated with the `subDelegatee`.
    /// @dev Returns the address of the Franchiser even it it does not yet exist,
    ///      thanks to CREATE2.
    /// @param subDelegatee The target `subDelegatee`.
    /// @return franchiser The Franchiser contract, whether or not it exists yet.
    function getFranchiser(address subDelegatee)
        external
        view
        returns (Franchiser franchiser);

    /// @notice Delegates `amount` of `votingToken` to `subDelegatee`.
    /// @dev Can only be called by the `delegatee`. The SubFranchiser associated
    ///      with the `subDelegatee` must not already be active.
    /// @param subDelegatee The address that will receive voting power.
    /// @param amount The address that will receive voting power.
    /// @return franchiser The Franchiser contract.
    function subDelegate(address subDelegatee, uint256 amount)
        external
        returns (Franchiser franchiser);

    /// @notice Undelegates to `subDelegatee`.
    /// @dev Can only be called by the `delegatee`. The SubFranchiser associated
    ///      with the `subDelegatee` must already be active.
    /// @param subDelegatee The address that voting power will be removed from.
    function unSubDelegate(address subDelegatee) external;

    /// @notice Transfers the contract's balance of `votingToken`, as well as the balance
    ///         of the SubFranchiser contracts associated with each active `subdelegatee`, to `to`.
    /// @dev Can only be called by the `owner`, which is enforced by the recall function of IOwnedDelegator.
    ///      Unwinds the SubFranchiser contracts of each `subDelegatee` before recalling.
    /// @param to The address that will receive tokens.
    function recall(address to) external;
}
