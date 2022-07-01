// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {Franchiser} from "../src/Franchiser.sol";

library Utils {
    address internal constant alice =
        0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address internal constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address internal constant carol =
        0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
    address internal constant dave = 0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd;
    address internal constant erin = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant frank =
        0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    function nestVertical(
        uint256 levels,
        Vm vm,
        VotingTokenConcrete votingToken,
        FranchiserFactory franchiserFactory
    ) internal returns (Franchiser[5] memory franchisers) {
        assert(levels != 0);
        assert(levels <= 5);
        assert(franchiserFactory.initialMaximumSubDelegatees() == 8);
        assert(franchiserFactory.franchiserImplementation().decayFactor() == 2);

        address[5] memory delegatees = [bob, carol, dave, erin, frank];

        votingToken.mint(alice, 1);
        vm.startPrank(alice);
        votingToken.approve(address(franchiserFactory), 1);
        franchisers[0] = franchiserFactory.fund(delegatees[0], 1);
        vm.stopPrank();

        unchecked {
            for (uint256 i = 1; i < levels; i++) {
                vm.prank(delegatees[i - 1]);
                franchisers[i] = franchisers[i - 1].subDelegate(
                    delegatees[i],
                    1
                );
            }
        }
    }

    function incrementNextDelegatee(address nextDelegatee)
        private
        pure
        returns (address)
    {
        return address(uint160(nextDelegatee) + 1);
    }

    function nestMaximum(
        Vm vm,
        VotingTokenConcrete votingToken,
        FranchiserFactory franchiserFactory
    ) internal returns (Franchiser[][5] memory franchisers) {
        assert(franchiserFactory.initialMaximumSubDelegatees() == 8);
        assert(franchiserFactory.franchiserImplementation().decayFactor() == 2);

        franchisers[0] = new Franchiser[](1);
        franchisers[1] = new Franchiser[](8);
        franchisers[2] = new Franchiser[](32);
        franchisers[3] = new Franchiser[](64);
        franchisers[4] = new Franchiser[](64);

        address nextDelegatee = address(2);

        votingToken.mint(address(1), 64);
        vm.startPrank(address(1));
        votingToken.approve(address(franchiserFactory), 64);
        franchisers[0][0] = franchiserFactory.fund(nextDelegatee, 64);
        vm.stopPrank();

        nextDelegatee = incrementNextDelegatee(nextDelegatee);

        unchecked {
            for (uint256 i; i < 8; i++) {
                address delegator = franchisers[0][0].delegatee();
                vm.prank(delegator);
                franchisers[1][i] = franchisers[0][0].subDelegate(
                    nextDelegatee,
                    8
                );
                nextDelegatee = address(uint160(nextDelegatee) + 1);
            }
            for (uint256 i; i < 32; i++) {
                uint256 j = i / 4;
                address delegator = franchisers[1][j].delegatee();
                vm.prank(delegator);
                franchisers[2][i] = franchisers[1][j].subDelegate(
                    nextDelegatee,
                    2
                );
                nextDelegatee = address(uint160(nextDelegatee) + 1);
            }
            for (uint256 i; i < 64; i++) {
                uint256 j = i / 2;
                address delegator = franchisers[2][j].delegatee();
                vm.prank(delegator);
                franchisers[3][i] = franchisers[2][j].subDelegate(
                    nextDelegatee,
                    1
                );
                nextDelegatee = address(uint160(nextDelegatee) + 1);
            }
            for (uint256 i; i < 64; i++) {
                address delegator = franchisers[3][i].delegatee();
                vm.prank(delegator);
                franchisers[4][i] = franchisers[3][i].subDelegate(
                    nextDelegatee,
                    1
                );
                nextDelegatee = address(uint160(nextDelegatee) + 1);
            }
        }
        assert(uint160(nextDelegatee) == 171);
    }
}
