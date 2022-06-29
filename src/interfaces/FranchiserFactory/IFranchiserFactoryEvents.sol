// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {Franchiser} from "../../Franchiser.sol";

/// @title Events for the FranchiserFactory contract.
interface IFranchiserFactoryEvents {
    /// @notice Emitted when a new Franchiser is created.
    /// @param owner The `owner`.
    /// @param delegatee The `delegatee`.
    /// @param franchiser The new Franchiser contract.
    event NewFranchiser(
        address indexed owner,
        address indexed delegatee,
        Franchiser franchiser
    );
}
