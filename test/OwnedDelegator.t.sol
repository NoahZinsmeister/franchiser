// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OwnedDelegator} from "../src/base/OwnedDelegator.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {IOwnedDelegatorErrors} from "../src/interfaces/OwnedDelegator/IOwnedDelegator.sol";
import {IOwnedDelegatorEvents} from "../src/interfaces/OwnedDelegator/IOwnedDelegator.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

contract OwnedDelegatorConcrete is OwnedDelegator {
    constructor(IVotingToken votingToken) OwnedDelegator(votingToken) {}
}

contract OwnedDelegatorTest is
    Test,
    IOwnedDelegatorErrors,
    IOwnedDelegatorEvents
{
    using Clones for address;

    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address private constant carol = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    VotingTokenConcrete private votingToken;
    OwnedDelegatorConcrete private ownedDelegator;

    function setUp() public {
        votingToken = new VotingTokenConcrete();
        vm.prank(alice);
        // we need to set this up as a clone to work
        ownedDelegator = OwnedDelegatorConcrete(
            address(
                new OwnedDelegatorConcrete(IVotingToken(address(votingToken)))
            ).clone()
        );
    }

    function testSetUp() public {
        assertEq(ownedDelegator.owner(), address(0));
        assertEq(ownedDelegator.delegatee(), address(0));
    }

    function testImplementationBroken() public {
        OwnedDelegatorConcrete ownedDelegatorConcrete = new OwnedDelegatorConcrete(
                IVotingToken(address(0))
            );
        assertEq(ownedDelegatorConcrete.owner(), address(0));
        assertEq(ownedDelegatorConcrete.delegatee(), address(1));
    }

    function testInitializeRevertsNoDelegatee() public {
        vm.expectRevert(NoDelegatee.selector);
        ownedDelegator.initialize(address(0), address(0));
    }

    function testInitialize() public {
        vm.expectEmit(true, true, false, true, address(ownedDelegator));
        emit Initialized(alice, bob);
        ownedDelegator.initialize(alice, bob);
        assertEq(ownedDelegator.owner(), alice);
        assertEq(ownedDelegator.delegatee(), bob);
        assertEq(votingToken.delegates(address(ownedDelegator)), bob);
    }

    function testInitializeRevertsAlreadyInitialized() public {
        ownedDelegator.initialize(alice, bob);
        vm.expectRevert(AlreadyInitialized.selector);
        ownedDelegator.initialize(address(0), address(1));
    }

    // fails because of onlyOwner
    function testFailRecall() public {
        ownedDelegator.recall(address(0));
    }

    function testRecallZero() public {
        vm.prank(address(0));
        ownedDelegator.recall(alice);
    }

    function testRecallNonZero() public {
        votingToken.mint(address(ownedDelegator), 100);
        vm.prank(address(0));
        ownedDelegator.recall(alice);
        assertEq(votingToken.balanceOf(alice), 100);
    }
}
