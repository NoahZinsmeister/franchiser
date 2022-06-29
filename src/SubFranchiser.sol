// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {OwnedDelegator} from "./base/OwnedDelegator.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";

contract SubFranchiser is OwnedDelegator {
    constructor(IVotingToken votingToken) OwnedDelegator(votingToken) {}
}
