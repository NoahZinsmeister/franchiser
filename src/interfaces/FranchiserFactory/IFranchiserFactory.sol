// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IFranchiserFactoryErrors} from "./IFranchiserFactoryErrors.sol";
import {IFranchiserFactoryEvents} from "./IFranchiserFactoryEvents.sol";
import {IFranchiserImmutableState} from "../IFranchiserImmutableState.sol";
import {Franchiser} from "../../Franchiser.sol";

/// @title Interface for the FranchiserFactory contract.
interface IFranchiserFactory is
    IFranchiserFactoryErrors,
    IFranchiserFactoryEvents,
    IFranchiserImmutableState
{
    /// @notice The initial value for the maximum number of `subDelegatee` addresses that a Franchiser
    ///         contract can have at any one time.
    /// @dev Decreases by half every level of nesting.
    /// @return initialMaximumSubDelegatees The intial maximum number of `subDelegatee` addresses.
    function initialMaximumSubDelegatees()
        external
        returns (uint256 initialMaximumSubDelegatees);

    /// @notice The implementation contract used to clone Franchiser contracts.
    /// @dev Used as part of an EIP-1167 proxy minimal proxy setup.
    /// @return franchiserImplementation The Franchiser implementation contract.
    function franchiserImplementation()
        external
        view
        returns (Franchiser franchiserImplementation);

    /// @notice Looks up the Franchiser associated with the `owner` and `delegatee`.
    /// @dev Returns the address of the Franchiser even it it does not yet exist,
    ///      thanks to CREATE2.
    /// @param owner The target `owner`.
    /// @param delegatee The target `delegatee`.
    /// @return franchiser The Franchiser contract, whether or not it exists yet.
    function getFranchiser(address owner, address delegatee)
        external
        view
        returns (Franchiser franchiser);

    /// @notice Funds the Franchiser contract associated with the `delegatee`
    ///         from the sender of the call.
    /// @dev Requires the sender of the call to have approved this contract for `amount`.
    ///      If a Franchiser does not yet exist, one is created.
    /// @param delegatee The target `delegatee`.
    /// @param amount The amount of `votingToken` to allocate.
    /// @return franchiser The Franchiser contract.
    function fund(address delegatee, uint256 amount)
        external
        returns (Franchiser franchiser);

    /// @notice Recalls funds in the Franchiser contract associated with the `delegatee`.
    /// @dev Can only be called by the `owner`. No-op if a Franchiser does not exist.
    /// @param delegatee The target `delegatee`.
    /// @param to The `votingToken` recipient.
    function recall(address delegatee, address to) external;

    /// @notice Funds the Franchiser contracts associated with the `delegatees`
    ///         from the sender of the call.
    /// @dev Requires the sender of the call to have approved this contract for sum of `amounts`.
    ///      If Franchiser do not yet exist, they are created.
    /// @param delegatees The target `delegatees`.
    /// @param amounts The amounts of `votingToken` to allocate.
    /// @return franchisers The Franchiser contracts.
    function fundMany(address[] calldata delegatees, uint256[] calldata amounts)
        external
        returns (Franchiser[] memory franchisers);

    /// @notice Funds the Franchiser contract associated with the `delegatee`
    ///         using a signature.
    /// @dev The signature must have been produced by the sener of the call.
    ///      If a Franchiser does not yet exist, one is created.
    /// @param delegatee The target `delegatee`.
    /// @param amount The amount of `votingToken` to allocate.
    /// @param deadline A timestamp which the current timestamp must be less than or equal to.
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the holder along with `v` and `r`.
    /// @return franchiser The Franchiser contract.
    function permitAndFund(
        address delegatee,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (Franchiser franchiser);
}
