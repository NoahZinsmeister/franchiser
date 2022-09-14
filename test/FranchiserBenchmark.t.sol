// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {IFranchiserErrors} from "../src/interfaces/Franchiser/IFranchiserErrors.sol";
import {IFranchiserEvents} from "../src/interfaces/Franchiser/IFranchiserEvents.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {Franchiser} from "../src/Franchiser.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {Utils} from "./Utils.sol";

contract FranchiserBenchmarkTest is Test, IFranchiserErrors, IFranchiserEvents {
    VotingTokenConcrete private votingToken;
    FranchiserFactory private franchiserFactory;

    uint256 maxDelegatees = 169; // 1 + 8 + 8*4 + 8*4*2 + 8*4*2

    mapping(address => address[]) subSubFranchisers;

    uint256 x = 10_000; // to generate addresses

    function setUp() public {
        votingToken = new VotingTokenConcrete();

        franchiserFactory = new FranchiserFactory(
            IVotingToken(address(votingToken))
        );
    }

    /// @notice Test max number of delegatees.
    ///         At the end of delegation, each subdelegate will have 1 token as voting power.
    function test() public {
        uint256 tokenCount = maxDelegatees;

        votingToken.mint(Utils.alice, tokenCount);

        // Alice delegates 169 to Bob
        vm.startPrank(Utils.alice);
        votingToken.approve(address(franchiserFactory), tokenCount);
        Franchiser franchiser = franchiserFactory.fund(Utils.bob, tokenCount);
        vm.stopPrank();

        // Bob delegates 8 accounts
        // Amount to delegate is (169 - 1) / 8 = 21
        uint256 numSubDelegates = uint256(franchiser.maximumSubDelegatees());
        tokenCount = (tokenCount - 1) / numSubDelegates;

        vm.startPrank(Utils.bob);
        address[] memory subFranchisers = new address[](numSubDelegates);
        for (uint256 i = 0; i < numSubDelegates; ) {
            address newAccount = _getNextAccount();

            address subFranchiserAddress = address(
                franchiser.subDelegate(newAccount, tokenCount)
            );

            assertEq(votingToken.balanceOf(subFranchiserAddress), tokenCount);
            assertEq(votingToken.getVotes(newAccount), tokenCount);

            subFranchisers[i] = subFranchiserAddress;

            unchecked {
                i++;
            }
        }
        vm.stopPrank();

        // Each SubFranchise delegates 4 accounts
        uint256 numSubSubDelegates = uint256(
            Franchiser(subFranchisers[0]).maximumSubDelegatees()
        );
        // Amount to delegate is (21 - 1) / 4 = 5
        tokenCount = (tokenCount - 1) / numSubSubDelegates;

        for (uint256 i = 0; i < subFranchisers.length; i++) {
            Franchiser subFranchiser = Franchiser(subFranchisers[i]);

            address subDelegatee = subFranchiser.delegatee();

            vm.startPrank(subDelegatee);

            for (uint256 j = 0; j < numSubSubDelegates; j++) {
                address newAccount = _getNextAccount();

                address subSubFranchiser = address(
                    subFranchiser.subDelegate(newAccount, tokenCount)
                );

                assertEq(votingToken.balanceOf(subSubFranchiser), tokenCount);
                assertEq(votingToken.getVotes(newAccount), tokenCount);

                subSubFranchisers[subDelegatee].push(subSubFranchiser);
            }

            vm.stopPrank();
        }

        // TODO: Do the rest of delegations

        // Each SubSubFranchise delegates 2 accounts
        // Amount to delegate is (5 - 1) / 2 = 2

        // Each SubSubFranchise delegates 1 accounts
        // Amount to delegate is (2 - 1) / 1 = 1

        // Recall
        vm.prank(Utils.alice);
        franchiserFactory.recall(Utils.bob, Utils.alice);

        // Check balances
        assertEq(votingToken.balanceOf(Utils.alice), maxDelegatees);

        /// Check votes
        assertEq(votingToken.getVotes(Utils.alice), 0);
    }

    function _getNextAccount() internal returns (address) {
        x++;
        return vm.addr(x);
    }
}
