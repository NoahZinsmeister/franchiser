// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {IFranchiserFactoryErrors} from "../src/interfaces/FranchiserFactory/IFranchiserFactoryErrors.sol";
import {IFranchiserFactoryEvents} from "../src/interfaces/FranchiserFactory/IFranchiserFactoryEvents.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {Franchiser} from "../src/Franchiser.sol";

contract FranchiserFactoryTest is
    Test,
    IFranchiserFactoryErrors,
    IFranchiserFactoryEvents
{
    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address private constant carol = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    VotingTokenConcrete private votingToken;
    FranchiserFactory private franchiserFactory;

    function setUp() public {
        votingToken = new VotingTokenConcrete();
        franchiserFactory = new FranchiserFactory(
            IVotingToken(address(votingToken))
        );
    }

    function testSetUp() public {
        assertEq(franchiserFactory.initialMaximumSubDelegatees(), 8);
        assertEq(
            franchiserFactory.franchiserImplementation().owner(),
            address(0)
        );
        assertEq(
            franchiserFactory.franchiserImplementation().delegatee(),
            address(1)
        );
    }

    function testFundZero() public {
        Franchiser expectedFranchiser = franchiserFactory.getFranchiser(
            alice,
            bob
        );

        vm.expectEmit(true, true, false, true, address(franchiserFactory));
        emit NewFranchiser(alice, bob, expectedFranchiser);

        vm.prank(alice);
        Franchiser franchiser = franchiserFactory.fund(bob, 0);

        assertEq(address(expectedFranchiser), address(franchiser));
        assertEq(franchiser.owner(), address(franchiserFactory));
        assertEq(franchiser.delegatee(), bob);
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

    function testFundManyRevertsArrayLengthMismatch() public {
        vm.expectRevert(
            abi.encodeWithSelector(ArrayLengthMismatch.selector, 0, 1)
        );
        franchiserFactory.fundMany(new address[](0), new uint256[](1));

        vm.expectRevert(
            abi.encodeWithSelector(ArrayLengthMismatch.selector, 1, 0)
        );
        franchiserFactory.fundMany(new address[](1), new uint256[](0));
    }

    function testFundMany() public {
        votingToken.mint(alice, 100);

        address[] memory delegatees = new address[](2);
        delegatees[0] = bob;
        delegatees[1] = carol;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50;
        amounts[1] = 50;

        vm.startPrank(alice);
        votingToken.approve(address(franchiserFactory), 100);
        Franchiser[] memory franchisers = franchiserFactory.fundMany(
            delegatees,
            amounts
        );
        vm.stopPrank();

        assertEq(votingToken.balanceOf(address(franchisers[0])), 50);
        assertEq(votingToken.balanceOf(address(franchisers[1])), 50);
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

    function testRecallManyRevertsArrayLengthMismatch() public {
        vm.expectRevert(
            abi.encodeWithSelector(ArrayLengthMismatch.selector, 0, 1)
        );
        franchiserFactory.recallMany(new address[](0), new address[](1));

        vm.expectRevert(
            abi.encodeWithSelector(ArrayLengthMismatch.selector, 1, 0)
        );
        franchiserFactory.recallMany(new address[](1), new address[](0));
    }

    function testRecallMany() public {
        votingToken.mint(alice, 100);

        address[] memory delegatees = new address[](2);
        delegatees[0] = bob;
        delegatees[1] = carol;

        address[] memory tos = new address[](2);
        tos[0] = alice;
        tos[1] = alice;

        vm.startPrank(alice);
        votingToken.approve(address(franchiserFactory), 100);
        franchiserFactory.fund(bob, 50);
        franchiserFactory.fund(carol, 50);
        franchiserFactory.recallMany(delegatees, tos);
        vm.stopPrank();

        assertEq(votingToken.balanceOf(alice), 100);
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

    function testPermitAndFundManyRevertsArrayLengthMismatch() public {
        vm.expectRevert(
            abi.encodeWithSelector(ArrayLengthMismatch.selector, 0, 1)
        );
        franchiserFactory.permitAndFundMany(
            new address[](0),
            new uint256[](1),
            0,
            0,
            0,
            0
        );

        vm.expectRevert(
            abi.encodeWithSelector(ArrayLengthMismatch.selector, 1, 0)
        );
        franchiserFactory.permitAndFundMany(
            new address[](1),
            new uint256[](0),
            0,
            0,
            0,
            0
        );
    }

    // fails because of overflow
    function testFailPermitAndFundMany() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = type(uint256).max;
        amounts[1] = 1;

        franchiserFactory.permitAndFundMany(
            new address[](2),
            amounts,
            0,
            0,
            0,
            0
        );
    }

    function testPermitAndFundMany() public {
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

        address[] memory delegatees = new address[](2);
        delegatees[0] = bob;
        delegatees[1] = carol;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50;
        amounts[1] = 50;

        vm.prank(owner);
        Franchiser[] memory franchisers = franchiserFactory.permitAndFundMany(
            delegatees,
            amounts,
            deadline,
            v,
            r,
            s
        );

        assertEq(votingToken.balanceOf(address(franchisers[0])), 50);
        assertEq(votingToken.balanceOf(address(franchisers[1])), 50);
    }
}
