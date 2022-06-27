// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IFranchiserEvents} from "./IFranchiserEvents.sol";

interface IFranchiser is IFranchiserEvents {
    /// @notice The current `beneficiary` of the contract.
    /// @return beneficiary The `beneficiary`.
    function beneficiary() external returns (address beneficiary);

    /// @notice Changes the `beneficiary` of the contract.
    /// @dev Can only be called by the `owner`.
    /// @param newBeneficiary The new `beneficiary`.
    function changeBeneficiary(address newBeneficiary) external;
}
