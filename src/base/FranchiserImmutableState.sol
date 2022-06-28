// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IFranchiserImmutableState} from "../interfaces/IFranchiserImmutableState.sol";
import {IVotingToken} from "../interfaces/IVotingToken.sol";

abstract contract FranchiserImmutableState is IFranchiserImmutableState {
    /// @inheritdoc IFranchiserImmutableState
    IVotingToken public immutable votingToken;

    constructor(IVotingToken votingToken_) {
        votingToken = votingToken_;
    }
}
