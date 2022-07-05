// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {IFranchiserErrors} from "../src/interfaces/Franchiser/IFranchiserErrors.sol";
import {IFranchiserEvents} from "../src/interfaces/Franchiser/IFranchiserEvents.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {Franchiser} from "../src/Franchiser.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {Utils} from "./Utils.sol";

contract FranchiserTest is Test, IFranchiserErrors, IFranchiserEvents {
    using Clones for address;

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
        assertEq(franchiserImplementation.decayFactor(), 2);
        assertEq(
            address(franchiserImplementation.franchiserImplementation()),
            address(franchiserImplementation)
        );
        assertEq(franchiserImplementation.owner(), address(0));
        assertEq(franchiserImplementation.delegator(), address(0));
        assertEq(franchiserImplementation.delegatee(), address(1));
        assertEq(franchiserImplementation.maximumSubDelegatees(), 0);
        assertEq(franchiserImplementation.subDelegatees(), new address[](0));

        assertEq(franchiser.decayFactor(), 2);
        assertEq(
            address(franchiser.franchiserImplementation()),
            address(franchiserImplementation)
        );
        assertEq(franchiser.owner(), address(0));
        assertEq(franchiser.delegator(), address(0));
        assertEq(franchiser.delegatee(), address(0));
        assertEq(franchiser.maximumSubDelegatees(), 0);
        assertEq(franchiser.subDelegatees(), new address[](0));
    }

    function testInitializeRevertsNoDelegatee() public {
        vm.expectRevert(NoDelegatee.selector);
        franchiser.initialize(address(0), 0);
        vm.expectRevert(NoDelegatee.selector);
        franchiser.initialize(Utils.alice, address(0), 0);
    }

    function testInitialize() public {
        vm.expectEmit(true, true, false, true, address(franchiser));
        emit Initialized(address(1), Utils.alice, Utils.bob, 1);
        vm.prank(address(1));
        franchiser.initialize(Utils.alice, Utils.bob, 1);

        assertEq(franchiser.owner(), address(1));
        assertEq(franchiser.delegator(), Utils.alice);
        assertEq(franchiser.delegatee(), Utils.bob);
        assertEq(franchiser.maximumSubDelegatees(), 1);
        assertEq(votingToken.delegates(address(franchiser)), Utils.bob);
    }

    function testInitializeNoDelegator() public {
        vm.expectEmit(true, true, false, true, address(franchiser));
        emit Initialized(address(1), address(0), Utils.bob, 1);
        vm.mockCall(
            address(1),
            abi.encodeWithSignature("delegatee()"),
            abi.encode(address(0))
        );
        vm.prank(address(1));
        franchiser.initialize(Utils.bob, 1);

        assertEq(franchiser.owner(), address(1));
        assertEq(franchiser.delegator(), address(0));
        assertEq(franchiser.delegatee(), Utils.bob);
        assertEq(franchiser.maximumSubDelegatees(), 1);
        assertEq(votingToken.delegates(address(franchiser)), Utils.bob);
    }

    function testInitializeRevertsAlreadyInitialized() public {
        franchiser.initialize(Utils.alice, Utils.bob, 0);
        vm.expectRevert(AlreadyInitialized.selector);
        franchiser.initialize(Utils.alice, Utils.bob, 0);
        vm.expectRevert(AlreadyInitialized.selector);
        franchiser.initialize(Utils.bob, 0);
    }

    function testInitializeRevertsAlreadyInitializedNoDelegator() public {
        vm.mockCall(
            address(1),
            abi.encodeWithSignature("delegatee()"),
            abi.encode(address(0))
        );
        vm.prank(address(1));
        franchiser.initialize(Utils.bob, 0);
        vm.expectRevert(AlreadyInitialized.selector);
        franchiser.initialize(Utils.bob, 0);
        vm.expectRevert(AlreadyInitialized.selector);
        franchiser.initialize(Utils.alice, Utils.bob, 0);
    }

    function testSubDelegateRevertsNotDelegatee() public {
        franchiser.initialize(Utils.alice, Utils.bob, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                NotDelegatee.selector,
                Utils.alice,
                Utils.bob
            )
        );
        vm.prank(Utils.alice);
        franchiser.subDelegate(address(1), 0);
    }

    function testSubDelegateRevertsCannotExceedMaximumSubDelegatees() public {
        franchiser.initialize(Utils.alice, Utils.bob, 0);
        vm.expectRevert(
            abi.encodeWithSelector(CannotExceedMaximumSubDelegatees.selector, 0)
        );
        vm.prank(Utils.bob);
        franchiser.subDelegate(address(1), 0);
    }

    function testSubDelegateZero() public {
        franchiser.initialize(Utils.alice, Utils.bob, 1);
        Franchiser expectedFranchiser = franchiser.getFranchiser(Utils.carol);

        vm.expectEmit(true, true, false, true, address(expectedFranchiser));
        emit Initialized(address(franchiser), Utils.bob, Utils.carol, 0);
        vm.expectEmit(true, false, false, true, address(franchiser));
        emit SubDelegateeActivated(Utils.carol, expectedFranchiser);

        vm.prank(Utils.bob);
        Franchiser returnedFranchiser = franchiser.subDelegate(Utils.carol, 0);

        assertEq(address(expectedFranchiser), address(returnedFranchiser));

        address[] memory expectedSubDelegatees = new address[](1);
        expectedSubDelegatees[0] = Utils.carol;
        assertEq(franchiser.subDelegatees(), expectedSubDelegatees);

        assertEq(returnedFranchiser.owner(), address(franchiser));
        assertEq(returnedFranchiser.delegator(), Utils.bob);
        assertEq(returnedFranchiser.delegatee(), Utils.carol);
        assertEq(returnedFranchiser.maximumSubDelegatees(), 0);
        assertEq(returnedFranchiser.subDelegatees(), new address[](0));
        assertEq(
            votingToken.delegates(address(returnedFranchiser)),
            Utils.carol
        );
    }

    function testSubDelegateZeroNested() public {
        franchiser.initialize(Utils.alice, Utils.bob, 2);

        vm.prank(Utils.bob);
        Franchiser carolFranchiser = franchiser.subDelegate(Utils.carol, 0);
        vm.prank(Utils.carol);
        Franchiser daveFranchiser = carolFranchiser.subDelegate(Utils.dave, 0);

        assertEq(carolFranchiser.maximumSubDelegatees(), 1);
        assertEq(daveFranchiser.maximumSubDelegatees(), 0);
    }

    function testSubDelegateRevertsSubDelegateeAlreadyActive() public {
        franchiser.initialize(Utils.alice, Utils.bob, 2);
        vm.prank(Utils.bob);
        franchiser.subDelegate(Utils.carol, 0);

        vm.expectRevert(
            abi.encodeWithSelector(
                SubDelegateeAlreadyActive.selector,
                Utils.carol
            )
        );
        vm.prank(Utils.bob);
        franchiser.subDelegate(Utils.carol, 0);
    }

    function testSubDelegateNonZeroFull() public {
        franchiser.initialize(Utils.alice, Utils.bob, 1);
        votingToken.mint(address(franchiser), 100);
        vm.prank(Utils.bob);
        Franchiser returnedFranchiser = franchiser.subDelegate(
            Utils.carol,
            100
        );

        assertEq(votingToken.balanceOf(address(returnedFranchiser)), 100);
    }

    function testSubDelegateNonZeroPartial() public {
        franchiser.initialize(Utils.alice, Utils.bob, 1);
        votingToken.mint(address(franchiser), 100);
        vm.prank(Utils.bob);
        Franchiser returnedFranchiser = franchiser.subDelegate(Utils.carol, 50);

        assertEq(votingToken.balanceOf(address(franchiser)), 50);
        assertEq(votingToken.balanceOf(address(returnedFranchiser)), 50);
    }

    function testSubDelegateManyRevertsArrayLengthMismatch() public {
        franchiser.initialize(Utils.alice, Utils.bob, 2);

        address[] memory subDelegatees = new address[](0);
        uint256[] memory amounts = new uint256[](1);

        vm.expectRevert(
            abi.encodeWithSelector(ArrayLengthMismatch.selector, 0, 1)
        );
        vm.prank(Utils.bob);
        franchiser.subDelegateMany(subDelegatees, amounts);
    }

    function testSubDelegateMany() public {
        franchiser.initialize(Utils.alice, Utils.bob, 2);

        address[] memory subDelegatees = new address[](2);
        subDelegatees[0] = Utils.carol;
        subDelegatees[1] = Utils.dave;

        uint256[] memory amounts = new uint256[](2);

        vm.prank(Utils.bob);
        Franchiser[] memory franchisers = franchiser.subDelegateMany(
            subDelegatees,
            amounts
        );
        assertEq(franchisers.length, 2);
    }

    function testUnSubDelegateRevertsNotDelegatee() public {
        franchiser.initialize(Utils.alice, Utils.bob, 1);
        vm.prank(Utils.bob);
        franchiser.subDelegate(Utils.carol, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                NotDelegatee.selector,
                Utils.alice,
                Utils.bob
            )
        );
        vm.prank(Utils.alice);
        franchiser.unSubDelegate(Utils.carol);
    }

    function testUnSubDelegateZero() public {
        franchiser.initialize(Utils.alice, Utils.bob, 1);

        vm.startPrank(Utils.bob);
        Franchiser returnedFranchiser = franchiser.subDelegate(Utils.carol, 0);
        vm.expectEmit(true, false, false, true, address(franchiser));
        emit SubDelegateeDeactivated(Utils.carol, returnedFranchiser);
        franchiser.unSubDelegate(Utils.carol);
        vm.stopPrank();

        assertEq(franchiser.subDelegatees(), new address[](0));
    }

    function testUnSubDelegateNonZero() public {
        franchiser.initialize(Utils.alice, Utils.bob, 1);
        votingToken.mint(address(franchiser), 100);

        vm.startPrank(Utils.bob);
        franchiser.subDelegate(Utils.carol, 100);
        franchiser.unSubDelegate(Utils.carol);
        vm.stopPrank();

        assertEq(franchiser.subDelegatees(), new address[](0));
        assertEq(votingToken.balanceOf(address(franchiser)), 100);
    }

    function testUnSubDelegateMany() public {
        franchiser.initialize(Utils.alice, Utils.bob, 2);

        address[] memory subDelegatees = new address[](2);
        subDelegatees[0] = Utils.carol;
        subDelegatees[1] = Utils.dave;

        vm.startPrank(Utils.bob);
        franchiser.subDelegate(Utils.carol, 0);
        franchiser.subDelegate(Utils.dave, 0);

        franchiser.unSubDelegateMany(subDelegatees);
        vm.stopPrank();
    }

    function testRecallRevertsUNAUTHORIZED() public {
        vm.expectRevert(bytes("UNAUTHORIZED"));
        vm.prank(address(1));
        franchiser.recall(address(0));
    }

    function testRecallZeroNoSubDelegatees() public {
        vm.startPrank(Utils.alice);
        franchiser.initialize(Utils.alice, Utils.bob, 0);
        franchiser.recall(Utils.alice);
        vm.stopPrank();
    }

    function testRecallNonZeroNoSubDelegatees() public {
        votingToken.mint(address(franchiser), 100);
        vm.startPrank(Utils.alice);
        franchiser.initialize(Utils.alice, Utils.bob, 0);
        franchiser.recall(Utils.alice);
        vm.stopPrank();
        assertEq(votingToken.balanceOf(address(Utils.alice)), 100);
    }

    function testRecallNonZeroOneSubDelegatee() public {
        votingToken.mint(address(franchiser), 100);
        vm.prank(Utils.alice);
        franchiser.initialize(Utils.alice, Utils.bob, 1);
        vm.prank(Utils.bob);
        franchiser.subDelegate(Utils.carol, 50);
        vm.prank(Utils.alice);
        franchiser.recall(Utils.alice);
        assertEq(votingToken.balanceOf(address(Utils.alice)), 100);
    }

    function testRecallNonZeroTwoSubDelegatees() public {
        votingToken.mint(address(franchiser), 100);
        vm.prank(Utils.alice);
        franchiser.initialize(Utils.alice, Utils.bob, 2);
        vm.startPrank(Utils.bob);
        franchiser.subDelegate(Utils.carol, 25);
        franchiser.subDelegate(Utils.dave, 25);
        vm.stopPrank();
        vm.prank(Utils.alice);
        franchiser.recall(Utils.alice);
        assertEq(votingToken.balanceOf(address(Utils.alice)), 100);
    }

    function testRecallNonZeroNestedSubDelegatees() public {
        votingToken.mint(address(franchiser), 100);

        vm.prank(Utils.alice);
        franchiser.initialize(Utils.alice, Utils.bob, 2);

        vm.prank(Utils.bob);
        Franchiser carolFranchiser = franchiser.subDelegate(Utils.carol, 25);
        vm.prank(Utils.carol);
        carolFranchiser.subDelegate(Utils.dave, 25);

        vm.prank(Utils.alice);
        franchiser.recall(Utils.alice);
        assertEq(votingToken.balanceOf(address(Utils.alice)), 100);
    }
}
