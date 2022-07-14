// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiserLens} from "./interfaces/IFranchiserLens.sol";
import {FranchiserImmutableState} from "./base/FranchiserImmutableState.sol";
import {FranchiserFactory} from "./FranchiserFactory.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";
import {Franchiser} from "./Franchiser.sol";

contract FranchiserLens is IFranchiserLens, FranchiserImmutableState {
    /// @dev The asserts in the constructor ensure that this is safe to encode as a constant.
    uint256 private constant MAXIMUM_NESTING_DEPTH = 5; // log2(8) + 2

    /// @inheritdoc IFranchiserLens
    FranchiserFactory public immutable franchiserFactory;

    constructor(IVotingToken votingToken_, FranchiserFactory franchiserFactory_)
        FranchiserImmutableState(votingToken_)
    {
        franchiserFactory = franchiserFactory_;
        assert(franchiserFactory.INITIAL_MAXIMUM_SUBDELEGATEES() == 8);
        assert(
            franchiserFactory.franchiserImplementation().DECAY_FACTOR() == 2
        );
    }

    /// @inheritdoc IFranchiserLens
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

    /// @inheritdoc IFranchiserLens
    function getVerticalDelegations(Franchiser franchiser)
        external
        view
        returns (Delegation[] memory delegations)
    {
        uint256 delegatorsSeen = 0;
        Delegation[MAXIMUM_NESTING_DEPTH] memory delegatorsTemporary;
        unchecked {
            while (address(franchiser) != address(franchiserFactory)) {
                delegatorsTemporary[delegatorsSeen++] = Delegation({
                    delegator: franchiser.delegator(),
                    delegatee: franchiser.delegatee(),
                    franchiser: franchiser
                });
                franchiser = Franchiser(franchiser.owner());
            }
            delegations = new Delegation[](delegatorsSeen);
            for (uint256 i = 0; i < delegatorsSeen; i++)
                delegations[delegatorsSeen - i - 1] = delegatorsTemporary[i];
        }
    }

    /// @inheritdoc IFranchiserLens
    function getHorizontalDelegations(Franchiser franchiser)
        public
        view
        returns (Delegation[] memory delegations)
    {
        address[] memory subDelegatees = franchiser.subDelegatees();
        delegations = new Delegation[](subDelegatees.length);
        unchecked {
            for (uint256 i = 0; i < subDelegatees.length; i++) {
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

    /// @inheritdoc IFranchiserLens
    function getAllDelegations(Franchiser franchiser)
        public
        view
        returns (DelegationWithVotes[][] memory delegationsWithVotes)
    {
        DelegationWithVotes[][MAXIMUM_NESTING_DEPTH]
            memory delegationsWithVotesTemporary;
        Delegation memory rootDelegation = getRootDelegation(franchiser);
        delegationsWithVotesTemporary[0] = new DelegationWithVotes[](1);
        delegationsWithVotesTemporary[0][0] = getVotes(rootDelegation);
        unchecked {
            for (uint256 i = 1; i < MAXIMUM_NESTING_DEPTH; i++) {
                Delegation[][] memory descendantsNested = new Delegation[][](
                    delegationsWithVotesTemporary[i - 1].length
                );
                uint256 totalDescendants;
                for (
                    uint256 j = 0;
                    j < delegationsWithVotesTemporary[i - 1].length;
                    j++
                ) {
                    descendantsNested[j] = getHorizontalDelegations(
                        delegationsWithVotesTemporary[i - 1][j].franchiser
                    );
                    totalDescendants += descendantsNested[j].length;
                }
                DelegationWithVotes[]
                    memory descendantsWithVotes = new DelegationWithVotes[](
                        totalDescendants
                    );
                uint256 descendantsIndex;
                for (uint256 j = 0; j < descendantsNested.length; j++)
                    for (uint256 k = 0; k < descendantsNested[j].length; k++)
                        descendantsWithVotes[descendantsIndex++] = getVotes(
                            descendantsNested[j][k]
                        );
                delegationsWithVotesTemporary[i] = descendantsWithVotes;
            }
            uint256 delegationsWithVotesIndex = 0;
            while (
                delegationsWithVotesIndex < MAXIMUM_NESTING_DEPTH &&
                delegationsWithVotesTemporary[delegationsWithVotesIndex]
                    .length !=
                0
            ) delegationsWithVotesIndex++;
            delegationsWithVotes = new DelegationWithVotes[][](
                delegationsWithVotesIndex
            );
            for (uint256 i = 0; i < delegationsWithVotes.length; i++)
                delegationsWithVotes[i] = delegationsWithVotesTemporary[i];
        }
    }

    /// @inheritdoc IFranchiserLens
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
