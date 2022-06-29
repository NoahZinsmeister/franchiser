// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IFranchiserErrors} from "./IFranchiserErrors.sol";
import {IFranchiserEvents} from "./IFranchiserEvents.sol";
import {IOwnedBeneficiary} from "../OwnedBeneficiary/IOwnedBeneficiary.sol";
import {SubFranchiser} from "../../SubFranchiser.sol";

/// @title Interface for the Franchiser contract.
interface IFranchiser is
    IFranchiserErrors,
    IFranchiserEvents,
    IOwnedBeneficiary
{
    /// @notice The maximum number of `subDelegatee` addresses that the contract can have at any one time.
    /// @return maximumActiveSubDelegatees The maximum number of `subDelegatee` addresses.
    function maximumActiveSubDelegatees()
        external
        returns (uint256 maximumActiveSubDelegatees);

    /// @notice The implementation contract used to clone SubFranchiser contracts.
    /// @dev Used as part of an EIP-1167 proxy minimal proxy setup.
    /// @return subFranchiserImplementation The SubFranchiser implementation contract.
    function subFranchiserImplementation()
        external
        view
        returns (SubFranchiser subFranchiserImplementation);

    /// @notice The list of active `subDelegatee` addresses.
    /// @return activeSubDelegatees The current `subDelegatee` addresses.
    function activeSubDelegatees()
        external
        returns (address[] memory activeSubDelegatees);

    /// @notice Looks up the SubFranchiser associated with the `subDelegatee`.
    /// @dev Returns the address of the SubFranchiser even it it does not yet exist,
    ///      thanks to CREATE2.
    /// @param subDelegatee The target `subDelegatee`.
    /// @return subFranchiser The SubFranchiser contract, whether or not it exists yet.
    function getSubFranchiser(address subDelegatee)
        external
        view
        returns (SubFranchiser subFranchiser);

    /// @notice Delegates `amount` of `votingToken` to `subDelegatee`.
    /// @dev Can only be called by the `beneficiary`. The SubFranchiser associated
    ///      with the `subDelegatee` must not already be active.
    /// @param amount The address that will receive voting power.
    /// @param subDelegatee The address that will receive voting power.
    function subDelegate(uint256 amount, address subDelegatee) external;

    /// @notice Undelegates to `subDelegatee`.
    /// @dev Can only be called by the `beneficiary`. The SubFranchiser associated
    ///      with the `subDelegatee` must already be active.
    /// @param subDelegatee The address that voting power will be removed from.
    function unSubDelegate(address subDelegatee) external;

    /// @notice Transfers the contract's balance of `votingToken`, as well as the balance
    ///         of the SubFranchiser contracts associated with each active `subdelegatee`, to `to`.
    /// @dev Can only be called by the `owner`, which is enforced by the recall function of OwnedBeneficiary.
    ///      Unwinds the SubFranchiser contracts of each `subDelegatee` before recalling.
    /// @param to The address that will receive tokens.
    function recall(address to) external;
}
