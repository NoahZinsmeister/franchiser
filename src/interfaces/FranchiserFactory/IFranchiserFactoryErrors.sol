// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Errors thrown by the FranchiserFactory contract.
interface IFranchiserFactoryErrors {
    /// @notice Emitted when array arguments have different cardinalities.
    /// @param delegateesLength The length of `delegatees`.
    /// @param amountsLength The length of `amounts`.
    error ArrayLengthMismatch(uint256 delegateesLength, uint256 amountsLength);
}
