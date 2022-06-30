// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IFranchiserErrors} from "./IFranchiserErrors.sol";
import {IFranchiserEvents} from "./IFranchiserEvents.sol";
import {Franchiser} from "../../Franchiser.sol";

/// @title Interface for the Franchiser contract.
interface IFranchiser is IFranchiserErrors, IFranchiserEvents {
    /// @notice The implementation contract used to clone Franchiser contracts.
    /// @dev Used as part of an EIP-1167 proxy minimal proxy setup.
    /// @return franchiserImplementation The Franchiser implementation contract.
    function franchiserImplementation()
        external
        view
        returns (Franchiser franchiserImplementation);

    /// @notice The address that delegated tokens to this address.
    /// @dev Can always be derived from the `delegatee` of the `owner`, except for
    ///      direct descendants of the FranchiserFactory.
    /// @return delegator The `delegator`.
    function delegator() external view returns (address delegator);

    /// @notice The `delegatee` of the contract.
    /// @dev Never changes after being set via initialize,
    ///      but is not immutable because this contract is used via EIP-1167 clones.
    /// @return delegatee The `delegatee`.
    function delegatee() external returns (address delegatee);

    /// @notice The maximum number of `subDelegatee` addresses that the contract can have at any one time.
    /// @return maximumSubDelegatees The maximum number of `subDelegatee` addresses.
    function maximumSubDelegatees()
        external
        returns (uint96 maximumSubDelegatees);

    /// @notice The list of current `subDelegatee` addresses.
    /// @return subDelegatees The current `subDelegatee` addresses.
    function subDelegatees() external returns (address[] memory subDelegatees);

    /// @notice Calls initialize with `delegator` set to address(0).
    /// @dev Used for all Franchiser initialization beyond the first level of nesting.
    /// @param delegatee The `delegatee`.
    /// @param maximumSubDelegatees The maximum number of `subDelegatee` addresses.
    function initialize(address delegatee, uint96 maximumSubDelegatees)
        external;

    /// @notice Can be called once to set the contract's `delegator`, `owner`,
    ///         `delegatee`, and `maximumSubDelegatees`.
    /// @dev The `owner` is always the sender of the call.
    /// @param delegator The `delegator`.
    /// @param delegatee The `delegatee`.
    /// @param maximumSubDelegatees The maximum number of `subDelegatee` addresses.
    function initialize(
        address delegator,
        address delegatee,
        uint96 maximumSubDelegatees
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
    /// @dev Can only be called by the `delegatee`. The Franchiser associated
    ///      with the `subDelegatee` must not already be active.
    /// @param subDelegatee The address that will receive voting power.
    /// @param amount The address that will receive voting power.
    /// @return franchiser The Franchiser contract.
    function subDelegate(address subDelegatee, uint256 amount)
        external
        returns (Franchiser franchiser);

    /// @notice Undelegates to `subDelegatee`.
    /// @dev Can only be called by the `delegatee`. No-op if the Franchiser associated
    ///      with the `subDelegatee does not exist, or the address is not a `subDelegatee`.
    /// @param subDelegatee The address that voting power will be removed from.
    function unSubDelegate(address subDelegatee) external;

    /// @notice Transfers the contract's balance of `votingToken`, as well as the balance
    ///         of all nested Franchiser contracts associated with each subDelegatee, to `to`.
    /// @dev Can only be called by the `owner`.
    /// @param to The address that will receive tokens.
    function recall(address to) external;
}
