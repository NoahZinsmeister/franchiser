// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {IFranchiserErrors} from "../src/interfaces/Franchiser/IFranchiserErrors.sol";
import {IFranchiserEvents} from "../src/interfaces/Franchiser/IFranchiserEvents.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {Franchiser} from "../src/Franchiser.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {FranchiserLens} from "../src/FranchiserLens.sol";
import {Utils} from "./Utils.sol";

/// @notice Test max number of delegates.
///         The test is set up so that at the end of delegation, each subdelegate
///         will have 1 token as voting power.
contract FranchiserBenchmarkTest is Test, IFranchiserErrors, IFranchiserEvents {
    VotingTokenConcrete private votingToken;
    FranchiserFactory private franchiserFactory;
    FranchiserLens private franchiserLens;

    // Storage for franchiser addresses.
    address[] franchisersLevelTwo = new address[](8);
    mapping(address => address[]) franchisersLevelThree;
    mapping(address => mapping(address => address[])) franchisersLevelFour;
    mapping(address => mapping(address => mapping(address => address[]))) franchisersLevelFive;

    // Sub delegate counts.

    /// @notice Initial sub delegate count is 8.
    uint256 constant SUB_DELEGATE_COUNT_LEVEL_ONE = 8;

    /// @notice Sub delegate for level two count is 8 / 2 = 4.
    uint256 constant SUB_DELEGATE_COUNT_LEVEL_TWO = 4;

    /// @notice Sub delegate for level three count is 4 / 2 = 2.
    uint256 constant SUB_DELEGATE_COUNT_LEVEL_THREE = 2;

    /// @notice Sub delegate for level four count is 2 / 2 = 1.
    uint256 constant SUB_DELEGATE_COUNT_LEVEL_FOUR = 1;

    /// @notice Sub delegate for level five count is 1 / 2 = 0.
    uint256 constant SUB_DELEGATE_COUNT_LEVEL_FIVE = 0;

    // Sub delegate votes.

    /// @notice Initial amount to delegate (1 + 8*4 + 8*4*2 + 8*4*2) = 169
    uint256 constant INITIAL_VOTES = 169;

    /// @notice Amount to delegate is (INITIAL_VOTES - 1) / 8 = 21
    uint256 constant SUB_DELEGATE_VOTES_LEVEL_ONE = 21;

    /// @notice Amount to delegate is (SUB_DELEGATE_VOTES_LEVEL_ONE - 1) / 4 = 5
    uint256 constant SUB_DELEGATE_VOTES_LEVEL_TWO = 5;

    /// @notice Amount to delegate is (SUB_DELEGATE_VOTES_LEVEL_TWO - 1) / 2 = 2
    uint256 constant SUB_DELEGATE_VOTES_LEVEL_THREE = 2;

    /// @notice Amount to delegate is (SUB_DELEGATE_VOTES_LEVEL_THREE - 1) / 1 = 1
    uint256 constant SUB_DELEGATE_VOTES_LEVEL_FOUR = 1;

    // Used to generate consecutive accounts.
    uint256 x = 10_000;

    function setUp() public {
        votingToken = new VotingTokenConcrete();

        franchiserFactory = new FranchiserFactory(
            IVotingToken(address(votingToken))
        );

        franchiserLens = new FranchiserLens(
            IVotingToken(address(votingToken)),
            franchiserFactory
        );

        // Mint initial votes to Alice
        votingToken.mint(Utils.alice, INITIAL_VOTES);

        // Alice delegates all votes to Bob to generate level one
        vm.startPrank(Utils.alice);
        votingToken.approve(address(franchiserFactory), INITIAL_VOTES);
        Franchiser franchiserLevelOne = franchiserFactory.fund(
            Utils.bob,
            INITIAL_VOTES
        );
        vm.stopPrank();

        assertEq(
            SUB_DELEGATE_COUNT_LEVEL_ONE,
            uint256(franchiserLevelOne.maximumSubDelegatees())
        );

        // Bob delegates to 8 accounts to generate level two
        for (uint256 i = 0; i < SUB_DELEGATE_COUNT_LEVEL_ONE; i++) {
            // Generate new account.
            address newAccount = _getNextAccount();

            // Get delegatee.
            address delegatee = franchiserLevelOne.delegatee();

            // Sub-delegate to a new account.
            vm.prank(delegatee);
            Franchiser subFranchiserLevelTwo = franchiserLevelOne.subDelegate(
                newAccount,
                SUB_DELEGATE_VOTES_LEVEL_ONE
            );

            assertEq(
                subFranchiserLevelTwo.maximumSubDelegatees(),
                SUB_DELEGATE_COUNT_LEVEL_TWO
            );

            // Store sub-franchiser.
            franchisersLevelTwo.push(address(subFranchiserLevelTwo));

            assertEq(
                votingToken.balanceOf(address(subFranchiserLevelTwo)),
                SUB_DELEGATE_VOTES_LEVEL_ONE
            );
            assertEq(
                votingToken.getVotes(newAccount),
                SUB_DELEGATE_VOTES_LEVEL_ONE
            );

            // Each sub-delegate delegates to 4 accounts to generate level three
            for (uint256 j = 0; j < SUB_DELEGATE_COUNT_LEVEL_TWO; j++) {
                // Generate new account.
                newAccount = _getNextAccount();

                // Get delegatee.
                delegatee = subFranchiserLevelTwo.delegatee();

                // Sub-delegate to a new account.
                vm.prank(delegatee);
                Franchiser subFranchiserLevelThree = subFranchiserLevelTwo
                    .subDelegate(newAccount, SUB_DELEGATE_VOTES_LEVEL_TWO);

                assertEq(
                    subFranchiserLevelThree.maximumSubDelegatees(),
                    SUB_DELEGATE_COUNT_LEVEL_THREE
                );

                // Store sub-franchiser.
                franchisersLevelThree[address(subFranchiserLevelTwo)].push(
                    address(subFranchiserLevelThree)
                );

                assertEq(
                    votingToken.balanceOf(address(subFranchiserLevelThree)),
                    SUB_DELEGATE_VOTES_LEVEL_TWO
                );
                assertEq(
                    votingToken.getVotes(newAccount),
                    SUB_DELEGATE_VOTES_LEVEL_TWO
                );

                // Each sub-delegate delegates to 2 accounts to generate level four
                for (uint256 k = 0; k < SUB_DELEGATE_COUNT_LEVEL_THREE; k++) {
                    // Generate new account.
                    newAccount = _getNextAccount();

                    // Get delegatee.
                    delegatee = subFranchiserLevelThree.delegatee();

                    // Sub-delegate to a new account.
                    vm.prank(delegatee);
                    Franchiser subFranchiserLevelFour = subFranchiserLevelThree
                        .subDelegate(
                            newAccount,
                            SUB_DELEGATE_VOTES_LEVEL_THREE
                        );

                    assertEq(
                        subFranchiserLevelFour.maximumSubDelegatees(),
                        SUB_DELEGATE_COUNT_LEVEL_FOUR
                    );

                    // Store sub-franchiser.
                    franchisersLevelFour[address(subFranchiserLevelTwo)][
                        address(subFranchiserLevelThree)
                    ].push(address(subFranchiserLevelFour));

                    assertEq(
                        votingToken.balanceOf(address(subFranchiserLevelFour)),
                        SUB_DELEGATE_VOTES_LEVEL_THREE
                    );
                    assertEq(
                        votingToken.getVotes(newAccount),
                        SUB_DELEGATE_VOTES_LEVEL_THREE
                    );

                    // Each sub-delegate delegates to 1 accounts to generate level five
                    // No loop needed since at this depth the Franchiser can only delegate to one account.

                    // Generate new account.
                    newAccount = _getNextAccount();

                    // Get delegatee.
                    delegatee = subFranchiserLevelFour.delegatee();

                    // Sub-delegate to a new account.
                    vm.prank(delegatee);
                    Franchiser subFranchiserLevelFive = subFranchiserLevelFour
                        .subDelegate(newAccount, SUB_DELEGATE_VOTES_LEVEL_FOUR);

                    assertEq(
                        subFranchiserLevelFive.maximumSubDelegatees(),
                        SUB_DELEGATE_COUNT_LEVEL_FIVE
                    );

                    // Store sub-franchiser.
                    franchisersLevelFive[address(subFranchiserLevelTwo)][
                        address(subFranchiserLevelThree)
                    ][address(subFranchiserLevelFour)].push(
                            address(subFranchiserLevelFive)
                        );

                    assertEq(
                        votingToken.balanceOf(address(subFranchiserLevelFive)),
                        SUB_DELEGATE_VOTES_LEVEL_FOUR
                    );
                    assertEq(
                        votingToken.getVotes(newAccount),
                        SUB_DELEGATE_VOTES_LEVEL_FOUR
                    );
                }
            }
        }
        vm.startPrank(Utils.alice);
    }

    function testMaxDelegatesRecallBenchmark() public {
        // Recall
        franchiserFactory.recall(Utils.bob, Utils.alice);
    }

    function _getNextAccount() internal returns (address) {
        x++;
        return vm.addr(x);
    }
}
