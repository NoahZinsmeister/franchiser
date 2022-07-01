// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {FranchiserImmutableState} from "./base/FranchiserImmutableState.sol";
import {FranchiserFactory} from "./FranchiserFactory.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";
import {Franchiser} from "./Franchiser.sol";

contract FranchiserLens is FranchiserImmutableState {
    error UnexpectedInitialMaximumSubDelegatees(
        uint256 expectedInitialMaximumSubDelegatees,
        uint256 initialMaximumSubDelegatees
    );

    uint256 private constant expectedInitialMaximumSubDelegatees = 8;
    uint256 private constant maximumNestingDepth = 5; // log2(expectedInitialMaximumSubDelegatees) + 2

    FranchiserFactory public immutable franchiserFactory;

    constructor(IVotingToken votingToken, FranchiserFactory franchiserFactory_)
        FranchiserImmutableState(votingToken)
    {
        franchiserFactory = franchiserFactory_;
        if (
            expectedInitialMaximumSubDelegatees !=
            franchiserFactory.initialMaximumSubDelegatees()
        )
            revert UnexpectedInitialMaximumSubDelegatees(
                expectedInitialMaximumSubDelegatees,
                franchiserFactory.initialMaximumSubDelegatees()
            );
    }

    struct Delegation {
        address delegator;
        address delegatee;
        Franchiser franchiser;
    }

    function getRootDelegation(Franchiser franchiser)
        public
        view
        returns (Delegation memory delegation)
    {
        while (franchiser.owner() != address(franchiserFactory))
            franchiser = Franchiser(franchiser.owner());
        return
            Delegation({
                delegator: franchiser.delegator(),
                delegatee: franchiser.delegatee(),
                franchiser: franchiser
            });
    }

    function getVerticalDelegations(Franchiser franchiser)
        external
        view
        returns (Delegation[] memory delegators)
    {
        uint256 delegatorsSeen;
        Delegation[] memory delegatorsTemporary = new Delegation[](
            maximumNestingDepth
        );
        unchecked {
            while (address(franchiser) != address(franchiserFactory)) {
                delegatorsTemporary[delegatorsSeen++] = Delegation({
                    delegator: franchiser.delegator(),
                    delegatee: franchiser.delegatee(),
                    franchiser: franchiser
                });
                franchiser = Franchiser(franchiser.owner());
            }
            if (delegatorsSeen == maximumNestingDepth)
                return delegatorsTemporary;
            delegators = new Delegation[](delegatorsSeen);
            for (uint256 i; i < delegatorsSeen; i++)
                delegators[i] = delegatorsTemporary[i];
        }
    }

    function getHorizontalDelegations(Franchiser franchiser)
        private
        view
        returns (Delegation[] memory delegations)
    {
        address[] memory subDelegatees = franchiser.subDelegatees();
        delegations = new Delegation[](subDelegatees.length);
        unchecked {
            for (uint256 i; i < subDelegatees.length; i++) {
                Franchiser subDelegateeFranchiser = franchiser.getFranchiser(
                    subDelegatees[i]
                );
                delegations[i] = Delegation({
                    delegator: subDelegateeFranchiser.delegator(),
                    delegatee: subDelegateeFranchiser.delegatee(),
                    franchiser: subDelegateeFranchiser
                });
            }
        }
    }

    struct DelegationWithVotes {
        address delegator;
        address delegatee;
        Franchiser franchiser;
        uint256 votes;
    }

    function getVotes(Delegation memory delegation)
        private
        view
        returns (DelegationWithVotes memory)
    {
        return
            DelegationWithVotes({
                delegator: delegation.delegator,
                delegatee: delegation.delegatee,
                franchiser: delegation.franchiser,
                votes: votingToken.balanceOf(address(delegation.franchiser))
            });
    }

    function getAllDelegations(Franchiser franchiser)
        public
        view
        returns (DelegationWithVotes[][] memory)
    {
        DelegationWithVotes[][]
            memory delegationsWithVotes = new DelegationWithVotes[][](
                maximumNestingDepth
            );
        Delegation memory rootDelegation = getRootDelegation(franchiser);
        delegationsWithVotes[0] = new DelegationWithVotes[](1);
        delegationsWithVotes[0][0] = getVotes(rootDelegation);
        unchecked {
            for (uint256 i = 1; i < maximumNestingDepth; i++) {
                Delegation[][] memory descendantsNested;
                descendantsNested = new Delegation[][](
                    delegationsWithVotes[i - 1].length
                );
                uint256 totalDescendants;
                for (uint256 j; j < delegationsWithVotes[i - 1].length; j++) {
                    descendantsNested[j] = getHorizontalDelegations(
                        delegationsWithVotes[i - 1][j].franchiser
                    );
                    totalDescendants += descendantsNested[j].length;
                }
                Delegation[] memory descendantsFlattened = new Delegation[](
                    totalDescendants
                );
                uint256 descendantsIndex;
                for (uint256 j; j < descendantsNested.length; j++)
                    for (uint256 k; k < descendantsNested[j].length; k++)
                        descendantsFlattened[
                            descendantsIndex++
                        ] = descendantsNested[j][k];
                DelegationWithVotes[]
                    memory descendantsWithVotes = new DelegationWithVotes[](
                        descendantsFlattened.length
                    );
                for (uint256 j; j < descendantsWithVotes.length; j++)
                    descendantsWithVotes[j] = getVotes(descendantsFlattened[j]);
                delegationsWithVotes[i] = descendantsWithVotes;
            }

            uint256 delegationsWithVotesIndex;
            for (
                ;
                delegationsWithVotesIndex < maximumNestingDepth;
                delegationsWithVotesIndex++
            )
                if (delegationsWithVotes[delegationsWithVotesIndex].length == 0)
                    break;

            DelegationWithVotes[][]
                memory delegationsWithVotesTruncated = new DelegationWithVotes[][](
                    delegationsWithVotesIndex
                );
            for (uint256 i; i < delegationsWithVotesTruncated.length; i++)
                delegationsWithVotesTruncated[i] = delegationsWithVotes[i];
            return delegationsWithVotesTruncated;
        }
    }

    function getAllDelegations(address owner, address delegatee)
        external
        view
        returns (DelegationWithVotes[][] memory)
    {
        return
            getAllDelegations(
                franchiserFactory.getFranchiser(owner, delegatee)
            );
    }
}
