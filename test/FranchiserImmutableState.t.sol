// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {FranchiserImmutableState} from "../src/base/FranchiserImmutableState.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";

contract FranchiserImmutableStateConcrete is FranchiserImmutableState {
    constructor(IVotingToken votingToken)
        FranchiserImmutableState(votingToken)
    {}
}

contract FranchiserImmutableStateTest is Test {
    FranchiserImmutableStateConcrete private franchiserImmutableState;

    function setUp() public {
        franchiserImmutableState = new FranchiserImmutableStateConcrete(
            IVotingToken(address(1))
        );
    }

    function testSetUp() public {
        assertEq(address(franchiserImmutableState.votingToken()), address(1));
    }
}
