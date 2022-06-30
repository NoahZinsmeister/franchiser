// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Errors thrown by the FranchiserFactory contract.
interface IFranchiserFactoryErrors {
    /// @notice Emitted when two array arguments have different cardinalities.
    /// @param length0 The length of the first array argument.
    /// @param length1 The length of the second array argument.
    error ArrayLengthMismatch(uint256 length0, uint256 length1);
}
