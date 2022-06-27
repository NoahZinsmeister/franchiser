// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Events emitted by the Franchiser contract.
/// @dev Making this a separate interface is a little overkill, but inheriting it
///      in our tests makes assertions against event emission easier.
interface IFranchiserEvents {
    /// @notice Emitted when the contract's `beneficiary` changes.
    /// @param previousBeneficiary The previous `beneficiary`.
    /// @param newBeneficiary The new `beneficiary`.
    event BeneficiaryChanged(
        address indexed previousBeneficiary,
        address indexed newBeneficiary
    );
}
