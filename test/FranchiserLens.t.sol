// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test, console2} from "forge-std/Test.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {FranchiserLens} from "../src/FranchiserLens.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {Franchiser} from "../src/Franchiser.sol";

contract FranchiserLensTest is Test {
    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address private constant carol = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
    address private constant dave = 0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd;
    address private constant erin = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant frank = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    VotingTokenConcrete private votingToken;
    FranchiserFactory private franchiserFactory;
    FranchiserLens private franchiserLens;

    function setUp() public {
        votingToken = new VotingTokenConcrete();
        franchiserFactory = new FranchiserFactory(
            IVotingToken(address(votingToken))
        );
        franchiserLens = new FranchiserLens(
            IVotingToken(address(votingToken)),
            franchiserFactory
        );
    }

    function testSetUp() public {
        assertEq(
            address(franchiserLens.franchiserFactory()),
            address(franchiserFactory)
        );
    }

    function testGetRootDelegationNoNesting() public {
        vm.prank(alice);
        Franchiser franchiser = franchiserFactory.fund(bob, 0);
        FranchiserLens.Delegation memory delegation = franchiserLens
            .getRootDelegation(franchiser);
        assertEq(delegation.delegator, alice);
        assertEq(delegation.delegatee, bob);
        assertEq(address(delegation.franchiser), address(franchiser));
    }

    function testGetRootDelegationNesting() public {
        vm.prank(alice);
        Franchiser bobFranchiser = franchiserFactory.fund(bob, 0);
        vm.prank(bob);
        Franchiser carolFranchiser = bobFranchiser.subDelegate(carol, 0);
        FranchiserLens.Delegation memory delegation = franchiserLens
            .getRootDelegation(carolFranchiser);

        assertEq(delegation.delegator, alice);
        assertEq(delegation.delegatee, bob);
        assertEq(address(delegation.franchiser), address(bobFranchiser));
    }

    function nestMaximumVertical()
        private
        returns (Franchiser[] memory franchisers)
    {
        franchisers = new Franchiser[](5);
        vm.prank(alice);
        franchisers[0] = franchiserFactory.fund(bob, 0);
        vm.prank(bob);
        franchisers[1] = franchisers[0].subDelegate(carol, 0);
        vm.prank(carol);
        franchisers[2] = franchisers[1].subDelegate(dave, 0);
        vm.prank(dave);
        franchisers[3] = franchisers[2].subDelegate(erin, 0);
        vm.prank(erin);
        franchisers[4] = franchisers[3].subDelegate(frank, 0);
    }

    function testGetRootDelegationMaximumNesting() public {
        Franchiser[] memory franchisers = nestMaximumVertical();
        FranchiserLens.Delegation memory delegation = franchiserLens
            .getRootDelegation(franchisers[franchisers.length - 1]);

        assertEq(delegation.delegator, alice);
        assertEq(delegation.delegatee, bob);
        assertEq(address(delegation.franchiser), address(franchisers[0]));
    }

    function testGetVerticalDelegationsNoNesting() public {
        vm.prank(alice);
        Franchiser franchiser = franchiserFactory.fund(bob, 0);
        FranchiserLens.Delegation[]
            memory delegations = new FranchiserLens.Delegation[](1);
        delegations[0] = FranchiserLens.Delegation({
            delegator: alice,
            delegatee: bob,
            franchiser: franchiser
        });
        assertEq(
            keccak256(
                abi.encode(franchiserLens.getVerticalDelegations(franchiser))
            ),
            keccak256(abi.encode(delegations))
        );
    }

    function testGetVerticalDelegationsNesting() public {
        vm.prank(alice);
        Franchiser bobFranchiser = franchiserFactory.fund(bob, 0);
        vm.prank(bob);
        Franchiser carolFranchiser = bobFranchiser.subDelegate(carol, 0);
        FranchiserLens.Delegation[]
            memory delegations = new FranchiserLens.Delegation[](2);
        delegations[0] = FranchiserLens.Delegation({
            delegator: bob,
            delegatee: carol,
            franchiser: carolFranchiser
        });
        delegations[1] = FranchiserLens.Delegation({
            delegator: alice,
            delegatee: bob,
            franchiser: bobFranchiser
        });
        assertEq(
            keccak256(
                abi.encode(
                    franchiserLens.getVerticalDelegations(carolFranchiser)
                )
            ),
            keccak256(abi.encode(delegations))
        );
    }

    function testGetVerticalDelegationsMaximumNesting() public {
        Franchiser[] memory franchisers = nestMaximumVertical();

        FranchiserLens.Delegation[]
            memory delegations = new FranchiserLens.Delegation[](5);
        delegations[0] = FranchiserLens.Delegation({
            delegator: erin,
            delegatee: frank,
            franchiser: franchisers[4]
        });
        delegations[1] = FranchiserLens.Delegation({
            delegator: dave,
            delegatee: erin,
            franchiser: franchisers[3]
        });
        delegations[2] = FranchiserLens.Delegation({
            delegator: carol,
            delegatee: dave,
            franchiser: franchisers[2]
        });
        delegations[3] = FranchiserLens.Delegation({
            delegator: bob,
            delegatee: carol,
            franchiser: franchisers[1]
        });
        delegations[4] = FranchiserLens.Delegation({
            delegator: alice,
            delegatee: bob,
            franchiser: franchisers[0]
        });
        assertEq(
            keccak256(
                abi.encode(
                    franchiserLens.getVerticalDelegations(
                        franchisers[franchisers.length - 1]
                    )
                )
            ),
            keccak256(abi.encode(delegations))
        );
    }

    function testGetAllDelegations() public {
        votingToken.mint(alice, 64);

        Franchiser[][5] memory franchisers;
        franchisers[0] = new Franchiser[](1);
        franchisers[1] = new Franchiser[](8);
        franchisers[2] = new Franchiser[](8 * 4);
        franchisers[3] = new Franchiser[](8 * 4 * 2);
        franchisers[4] = new Franchiser[](8 * 4 * 2);

        vm.startPrank(alice);
        votingToken.approve(address(franchiserFactory), 64);
        franchisers[0][0] = franchiserFactory.fund(bob, 64);
        vm.stopPrank();

        address nextDelegatee = address(1);
        unchecked {
            for (uint256 i; i < 8; i++) {
                vm.prank(bob);
                franchisers[1][i] = franchisers[0][0].subDelegate(
                    nextDelegatee,
                    8
                );
                nextDelegatee = address(uint160(nextDelegatee) + 1);
            }
            for (uint256 i; i < 8 * 4; i++) {
                uint256 j = i / 4;
                address delegator = franchisers[1][j].delegatee();
                vm.prank(delegator);
                franchisers[2][i] = franchisers[1][j].subDelegate(
                    nextDelegatee,
                    8 / 4
                );
                nextDelegatee = address(uint160(nextDelegatee) + 1);
            }
            for (uint256 i; i < 8 * 4 * 2; i++) {
                uint256 j = i / 2;
                address delegator = franchisers[2][j].delegatee();
                vm.prank(delegator);
                franchisers[3][i] = franchisers[2][j].subDelegate(
                    nextDelegatee,
                    8 / 4 / 2
                );
                nextDelegatee = address(uint160(nextDelegatee) + 1);
            }
            for (uint256 i; i < 8 * 4 * 2; i++) {
                address delegator = franchisers[3][i].delegatee();
                vm.prank(delegator);
                franchisers[4][i] = franchisers[3][i].subDelegate(
                    nextDelegatee,
                    8 / 4 / 2
                );
                nextDelegatee = address(uint160(nextDelegatee) + 1);
            }
        }

        assertEq(uint160(nextDelegatee), 1 + 8 + 32 + 64 * 2);

        FranchiserLens.DelegationWithVotes[][]
            memory delegationsWithVotes = franchiserLens.getAllDelegations(
                franchisers[0][0]
            );
        assertEq(delegationsWithVotes.length, 5);
        assertEq(delegationsWithVotes[0].length, 1);
        assertEq(delegationsWithVotes[1].length, 8);
        assertEq(delegationsWithVotes[2].length, 8 * 4);
        assertEq(delegationsWithVotes[3].length, 8 * 4 * 2);
        assertEq(delegationsWithVotes[4].length, 8 * 4 * 2);

        assertEq(delegationsWithVotes[0][0].delegator, alice);
        assertEq(delegationsWithVotes[0][0].delegatee, bob);
        assertEq(
            address(delegationsWithVotes[0][0].franchiser),
            address(franchisers[0][0])
        );
        assertEq(delegationsWithVotes[0][0].votes, 0);

        unchecked {
            for (uint256 i; i < delegationsWithVotes.length; i++)
                for (uint256 j; j < delegationsWithVotes[i].length; j++)
                    assertEq(delegationsWithVotes[i][j].votes, i == 4 ? 1 : 0);
        }
    }
}
