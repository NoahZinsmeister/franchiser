// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Errors thrown by the Franchiser contract.
/// @dev Making this a separate interface is a little overkill, but inheriting it
///      in our tests makes assertions against errors easier.
interface IFranchiserErrors {
    error NotBeneficiary(address caller, address beneficiary);
}
