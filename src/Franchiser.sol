// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiser} from "./interfaces/IFranchiser.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Franchiser is IFranchiser, Ownable {
    /// @inheritdoc IFranchiser
    address public beneficiary;

    constructor(address owner) {
        transferOwnership(owner);
    }

    /// @inheritdoc IFranchiser
    function changeBeneficiary(address newBeneficiary) external onlyOwner {
        address previousBeneficiary = beneficiary;
        beneficiary = newBeneficiary;
        emit BeneficiaryChanged(previousBeneficiary, newBeneficiary);
    }
}
