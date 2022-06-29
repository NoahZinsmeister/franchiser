// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IOwnedDelegator} from "../interfaces/OwnedDelegator/IOwnedDelegator.sol";
import {FranchiserImmutableState} from "./FranchiserImmutableState.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {IVotingToken} from "../interfaces/IVotingToken.sol";

abstract contract OwnedDelegator is
    IOwnedDelegator,
    FranchiserImmutableState,
    Owned
{
    using SafeTransferLib for ERC20;

    address private _delegatee;

    /// @inheritdoc IOwnedDelegator
    function delegatee() external view returns (address) {
        return _delegatee;
    }

    /// @dev Reverts if called by any account other than the `delegatee`.
    modifier onlyDelegatee() {
        if (msg.sender != _delegatee)
            revert NotDelegatee(msg.sender, _delegatee);
        _;
    }

    constructor(IVotingToken votingToken)
        FranchiserImmutableState(votingToken)
        Owned(address(0))
    {
        // this borks the implementation contract as desired,
        // new instances should be cloned.
        _delegatee = address(1);
    }

    /// @inheritdoc IOwnedDelegator
    function initialize(address owner_, address delegatee_) public {
        // the following two conditions, along with the fact
        // that _delegatee is private and only set below (outside of the constructor),
        // ensures that intialize can only be called once in clones
        if (delegatee_ == address(0)) revert NoDelegatee();
        if (_delegatee != address(0)) revert AlreadyInitialized();
        owner = owner_;
        _delegatee = delegatee_;
        votingToken.delegate(delegatee_);
        emit Initialized(owner_, delegatee_);
    }

    /// @inheritdoc IOwnedDelegator
    function recall(address to) public virtual onlyOwner {
        ERC20(address(votingToken)).safeTransfer(
            to,
            votingToken.balanceOf(address(this))
        );
    }
}
