// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {IFranchiserFactoryEvents} from "../src/interfaces/FranchiserFactory/IFranchiserFactoryEvents.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {Franchiser} from "../src/Franchiser.sol";

contract OwnedBeneficiaryTest is Test, IFranchiserFactoryEvents {
    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

    VotingTokenConcrete private votingToken;
    FranchiserFactory private franchiserFactory;

    function setUp() public {
        votingToken = new VotingTokenConcrete();
        franchiserFactory = new FranchiserFactory(
            IVotingToken(address(votingToken))
        );
    }

    function testSetUp() public {
        assertEq(
            franchiserFactory.franchiserImplementation().owner(),
            address(0)
        );
        assertEq(
            franchiserFactory.franchiserImplementation().beneficiary(),
            address(1)
        );
    }

    function testFundZero() public {
        Franchiser expectedFranchiser = franchiserFactory.franchisers(
            alice,
            bob
        );

        vm.expectEmit(true, true, false, true, address(franchiserFactory));
        emit NewFranchiser(alice, bob, expectedFranchiser);

        vm.prank(alice);
        Franchiser franchiser = franchiserFactory.fund(bob, 0);

        assertEq(address(expectedFranchiser), address(franchiser));
        assertEq(franchiser.owner(), address(franchiserFactory));
        assertEq(franchiser.beneficiary(), bob);
        assertEq(votingToken.delegates(address(franchiser)), bob);
    }

    // fails because no allowance is given to franchiserFactory
    function testFailFundNonZero() public {
        franchiserFactory.fund(bob, 100);
    }

    function testFundNonZero() public {
        votingToken.mint(alice, 100);

        vm.startPrank(alice);
        votingToken.approve(address(franchiserFactory), 100);
        Franchiser franchiser = franchiserFactory.fund(bob, 100);
        vm.stopPrank();

        assertEq(votingToken.balanceOf(address(franchiser)), 100);
        assertEq(votingToken.getVotes(bob), 100);
    }

    function testRecallZero() public {
        franchiserFactory.recall(bob, alice);
    }

    function testRecallNonZero() public {
        votingToken.mint(alice, 100);

        vm.startPrank(alice);
        votingToken.approve(address(franchiserFactory), 100);
        Franchiser franchiser = franchiserFactory.fund(bob, 100);
        franchiserFactory.recall(bob, alice);
        vm.stopPrank();

        assertEq(votingToken.balanceOf(address(franchiser)), 0);
        assertEq(votingToken.balanceOf(alice), 100);
        assertEq(votingToken.getVotes(bob), 0);
    }

    function testPermitAndFund() public {
        (
            address owner,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = votingToken.getPermitSignature(
                vm,
                0xa11ce,
                address(franchiserFactory),
                100
            );
        votingToken.mint(owner, 100);
        vm.prank(owner);
        Franchiser franchiser = franchiserFactory.permitAndFund(
            bob,
            100,
            deadline,
            v,
            r,
            s
        );

        assertEq(votingToken.balanceOf(address(franchiser)), 100);
        assertEq(votingToken.getVotes(bob), 100);
    }
}
