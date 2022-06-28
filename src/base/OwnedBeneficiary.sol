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

    address private _beneficiary;

    /// @dev Reverts if called by any account other than the `beneficiary`.
    modifier onlyBeneficiary() {
        if (msg.sender != _beneficiary)
            revert NotBeneficiary(msg.sender, _beneficiary);
        _;
    }

    constructor(IVotingToken votingToken)
        FranchiserImmutableState(votingToken)
        Owned(address(0))
    {}

    /// @inheritdoc IOwnedBeneficiary
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    /// @inheritdoc IOwnedBeneficiary
    function initialize(address owner_, address beneficiary_) external {
        // the following two conditions, along with the fact
        // that _beneficiary is private and only set below,
        // ensure that intialize can only be called once
        if (beneficiary_ == address(0)) revert ZeroBeneficiary();
        if (_beneficiary != address(0)) revert AlreadyInitialized();
        owner = owner_;
        _beneficiary = beneficiary_;
        emit Initialized(owner_, beneficiary_);
        // self-delegate by default
        _delegate(_beneficiary);
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
