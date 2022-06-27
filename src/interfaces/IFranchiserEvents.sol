// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

interface IFranchiserEvents {
    /// @notice Emitted when the contract's `beneficiary` changes.
    /// @param previousBeneficiary The previous `beneficiary`.
    /// @param newBeneficiary The new `beneficiary`.
    event BeneficiaryChanged(
        address indexed previousBeneficiary,
        address indexed newBeneficiary
    );
}
