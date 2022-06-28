// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IOwnedBeneficiary} from "../interfaces/OwnedBeneficiary/IOwnedBeneficiary.sol";
import {FranchiserImmutableState} from "./FranchiserImmutableState.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {IVotingToken} from "../interfaces/IVotingToken.sol";

abstract contract OwnedBeneficiary is
    IOwnedBeneficiary,
    FranchiserImmutableState,
    Owned
{
    using SafeTransferLib for ERC20;

    /// @inheritdoc IOwnedBeneficiary
    address public beneficiary;

    /// @dev Reverts if called by any account other than the `beneficiary`.
    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary)
            revert NotBeneficiary(msg.sender, beneficiary);
        _;
    }

    constructor(IVotingToken votingToken)
        FranchiserImmutableState(votingToken)
        Owned(msg.sender)
    {}

    /// @inheritdoc IOwnedBeneficiary
    function initialize(address beneficiary_) external onlyOwner {
        if (beneficiary_ == address(0)) revert ZeroBeneficiary();
        if (beneficiary != address(0)) revert AlreadyInitialized();
        beneficiary = beneficiary_;
        emit Initialized(beneficiary);
        // self-delegate by default
        _delegate(beneficiary_);
    }

    /// @inheritdoc IOwnedBeneficiary
    function delegate(address delegatee) external onlyBeneficiary {
        _delegate(delegatee);
    }

    function _delegate(address delegatee) private {
        votingToken.delegate(delegatee);
    }

    /// @inheritdoc IOwnedBeneficiary
    function recall(address to) external onlyOwner {
        ERC20(address(votingToken)).safeTransfer(
            to,
            votingToken.balanceOf(address(this))
        );
    }
}
