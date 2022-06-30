// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {IFranchiserErrors} from "../src/interfaces/Franchiser/IFranchiserErrors.sol";
import {IFranchiserEvents} from "../src/interfaces/Franchiser/IFranchiserEvents.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {Franchiser} from "../src/Franchiser.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

contract FranchiserTest is Test, IFranchiserErrors, IFranchiserEvents {
    using Clones for address;

    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address private constant carol = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
    address private constant dave = 0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd;

    VotingTokenConcrete private votingToken;
    Franchiser private franchiserImplementation;
    Franchiser private franchiser;

    function setUp() public {
        votingToken = new VotingTokenConcrete();
        franchiserImplementation = new Franchiser(
            IVotingToken(address(votingToken))
        );
        // we need to set this up as a clone to work
        franchiser = Franchiser(address(franchiserImplementation).clone());
    }

    function testSetUp() public {
        assertEq(
            address(franchiser.franchiserImplementation()),
            address(franchiserImplementation)
        );
        assertEq(franchiser.owner(), address(0));
        assertEq(franchiser.delegatee(), address(0));
        assertEq(franchiser.maximumSubDelegatees(), 0);
        assertEq(franchiser.subDelegatees(), new address[](0));
    }

    function testImplementationBroken() public {
        assertEq(
            address(franchiserImplementation.franchiserImplementation()),
            address(franchiserImplementation)
        );
        assertEq(franchiserImplementation.owner(), address(0));
        assertEq(franchiserImplementation.delegatee(), address(1));
        assertEq(franchiserImplementation.maximumSubDelegatees(), 0);
        assertEq(franchiserImplementation.subDelegatees(), new address[](0));
    }

    function testInitializeRevertsNoDelegatee() public {
        vm.expectRevert(NoDelegatee.selector);
        franchiser.initialize(alice, address(0), 0);
    }

    function testInitialize() public {
        vm.expectEmit(true, true, false, true, address(franchiser));
        emit Initialized(alice, bob, 1);
        franchiser.initialize(alice, bob, 1);
        assertEq(franchiser.owner(), alice);
        assertEq(franchiser.delegatee(), bob);
        assertEq(franchiser.maximumSubDelegatees(), 1);
        assertEq(franchiser.subDelegatees(), new address[](0));
        assertEq(votingToken.delegates(address(franchiser)), bob);
    }

    function testInitializeRevertsAlreadyInitialized() public {
        franchiser.initialize(alice, bob, 0);
        vm.expectRevert(AlreadyInitialized.selector);
        franchiser.initialize(alice, bob, 0);
    }

    function testSubDelegateRevertsNotDelegatee() public {
        franchiser.initialize(alice, bob, 0);
        vm.expectRevert(
            abi.encodeWithSelector(NotDelegatee.selector, alice, bob)
        );
        vm.prank(alice);
        franchiser.subDelegate(address(1), 0);
    }

    function testSubDelegateRevertsCannotExceedMaximumSubDelegatees() public {
        franchiser.initialize(alice, bob, 0);
        vm.expectRevert(
            abi.encodeWithSelector(CannotExceedMaximumSubDelegatees.selector, 0)
        );
        vm.prank(bob);
        franchiser.subDelegate(address(1), 0);
    }

    function testSubDelegateZero() public {
        franchiser.initialize(alice, bob, 1);
        Franchiser expectedFranchiser = franchiser.getFranchiser(carol);

        vm.expectEmit(true, true, false, true, address(expectedFranchiser));
        emit Initialized(address(franchiser), carol, 0);
        vm.expectEmit(true, false, false, true, address(franchiser));
        emit SubDelegateeActivated(carol, expectedFranchiser);

        vm.prank(bob);
        Franchiser returnedFranchiser = franchiser.subDelegate(carol, 0);

        assertEq(address(expectedFranchiser), address(returnedFranchiser));

        address[] memory expectedSubDelegatees = new address[](1);
        expectedSubDelegatees[0] = carol;
        assertEq(franchiser.subDelegatees(), expectedSubDelegatees);

        assertEq(returnedFranchiser.maximumSubDelegatees(), 0);
        assertEq(returnedFranchiser.subDelegatees(), new address[](0));
        assertEq(returnedFranchiser.owner(), address(franchiser));
        assertEq(returnedFranchiser.delegatee(), carol);
        assertEq(votingToken.delegates(address(returnedFranchiser)), carol);
    }

    function testSubDelegateZeroNested() public {
        franchiser.initialize(alice, bob, 2);

        vm.prank(bob);
        Franchiser carolFranchiser = franchiser.subDelegate(carol, 0);
        vm.prank(carol);
        Franchiser daveFranchiser = carolFranchiser.subDelegate(dave, 0);

        assertEq(carolFranchiser.maximumSubDelegatees(), 1);
        assertEq(daveFranchiser.maximumSubDelegatees(), 0);
    }

    function testSubDelegateRevertsSubDelegateeAlreadyActive() public {
        franchiser.initialize(alice, bob, 2);
        vm.prank(bob);
        franchiser.subDelegate(carol, 0);

        vm.expectRevert(
            abi.encodeWithSelector(SubDelegateeAlreadyActive.selector, carol)
        );
        vm.prank(bob);
        franchiser.subDelegate(carol, 0);
    }

    function testSubDelegateNonZeroFull() public {
        franchiser.initialize(alice, bob, 1);
        votingToken.mint(address(franchiser), 100);
        vm.prank(bob);
        Franchiser returnedFranchiser = franchiser.subDelegate(carol, 100);

        assertEq(votingToken.balanceOf(address(returnedFranchiser)), 100);
    }

    function testSubDelegateNonZeroPartial() public {
        franchiser.initialize(alice, bob, 1);
        votingToken.mint(address(franchiser), 100);
        vm.prank(bob);
        Franchiser returnedFranchiser = franchiser.subDelegate(carol, 50);

        assertEq(votingToken.balanceOf(address(franchiser)), 50);
        assertEq(votingToken.balanceOf(address(returnedFranchiser)), 50);
    }

    function testUnSubDelegateRevertsNotDelegatee() public {
        franchiser.initialize(alice, bob, 1);
        vm.prank(bob);
        franchiser.subDelegate(carol, 0);
        vm.expectRevert(
            abi.encodeWithSelector(NotDelegatee.selector, alice, bob)
        );
        vm.prank(alice);
        franchiser.unSubDelegate(carol);
    }

    function testUnSubDelegateZero() public {
        franchiser.initialize(alice, bob, 1);

        vm.startPrank(bob);
        Franchiser returnedFranchiser = franchiser.subDelegate(carol, 0);
        vm.expectEmit(true, false, false, true, address(franchiser));
        emit SubDelegateeDeactivated(carol, returnedFranchiser);
        franchiser.unSubDelegate(carol);
        vm.stopPrank();

        assertEq(franchiser.subDelegatees(), new address[](0));
    }

    function testUnSubDelegateNonZero() public {
        franchiser.initialize(alice, bob, 1);
        votingToken.mint(address(franchiser), 100);

        vm.startPrank(bob);
        franchiser.subDelegate(carol, 100);
        franchiser.unSubDelegate(carol);
        vm.stopPrank();

        assertEq(franchiser.subDelegatees(), new address[](0));
        assertEq(votingToken.balanceOf(address(franchiser)), 100);
    }

    // fails because of onlyOwner
    function testFailRecall() public {
        vm.prank(address(1));
        franchiser.recall(address(0));
    }

    function testRecallZeroNoSubDelegatees() public {
        franchiser.initialize(alice, bob, 0);
        vm.prank(alice);
        franchiser.recall(alice);
    }

    function testRecallNonZeroNoSubDelegatees() public {
        franchiser.initialize(alice, bob, 0);
        votingToken.mint(address(franchiser), 100);
        vm.prank(alice);
        franchiser.recall(alice);
        assertEq(votingToken.balanceOf(address(alice)), 100);
    }

    function testRecallNonZeroOneSubDelegatee() public {
        franchiser.initialize(alice, bob, 1);
        votingToken.mint(address(franchiser), 100);
        vm.prank(bob);
        franchiser.subDelegate(carol, 50);
        vm.prank(alice);
        franchiser.recall(alice);
        assertEq(votingToken.balanceOf(address(alice)), 100);
    }

    function testRecallNonZeroTwoSubDelegatees() public {
        franchiser.initialize(alice, bob, 2);
        votingToken.mint(address(franchiser), 100);
        vm.startPrank(bob);
        franchiser.subDelegate(carol, 25);
        franchiser.subDelegate(dave, 25);
        vm.stopPrank();
        vm.prank(alice);
        franchiser.recall(alice);
        assertEq(votingToken.balanceOf(address(alice)), 100);
    }

    function testRecallNonZeroNestedSubDelegatees() public {
        franchiser.initialize(alice, bob, 2);
        votingToken.mint(address(franchiser), 100);

        vm.prank(bob);
        Franchiser carolFranchiser = franchiser.subDelegate(carol, 25);
        vm.prank(carol);
        carolFranchiser.subDelegate(dave, 25);

        vm.prank(alice);
        franchiser.recall(alice);
        assertEq(votingToken.balanceOf(address(alice)), 100);
    }
}
