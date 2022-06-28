// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {OwnedBeneficiary} from "./base/OwnedBeneficiary.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";

contract Franchiser is OwnedBeneficiary {
    constructor(IVotingToken votingToken) OwnedBeneficiary(votingToken) {}
}
