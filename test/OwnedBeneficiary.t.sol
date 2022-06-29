// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OwnedBeneficiary} from "../src/base/OwnedBeneficiary.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {IOwnedBeneficiaryErrors} from "../src/interfaces/OwnedBeneficiary/IOwnedBeneficiaryErrors.sol";
import {IOwnedBeneficiaryEvents} from "../src/interfaces/OwnedBeneficiary/IOwnedBeneficiaryEvents.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

contract OwnedBeneficiaryConcrete is OwnedBeneficiary {
    constructor(IVotingToken votingToken) OwnedBeneficiary(votingToken) {}
}

contract OwnedBeneficiaryTest is
    Test,
    IOwnedBeneficiaryErrors,
    IOwnedBeneficiaryEvents
{
    using Clones for address;

    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address private constant carol = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    VotingTokenConcrete private votingToken;
    OwnedBeneficiaryConcrete private ownedBeneficiary;

    function setUp() public {
        votingToken = new VotingTokenConcrete();
        vm.prank(alice);
        // we need to set this up as a clone to work
        ownedBeneficiary = OwnedBeneficiaryConcrete(
            address(
                new OwnedBeneficiaryConcrete(IVotingToken(address(votingToken)))
            ).clone()
        );
    }

    function testSetUp() public {
        assertEq(ownedBeneficiary.owner(), address(0));
        assertEq(ownedBeneficiary.beneficiary(), address(0));
    }

    function testImplementationBroken() public {
        OwnedBeneficiaryConcrete ownedBeneficiaryConcrete = new OwnedBeneficiaryConcrete(
                IVotingToken(address(0))
            );
        assertEq(ownedBeneficiaryConcrete.owner(), address(0));
        assertEq(ownedBeneficiaryConcrete.beneficiary(), address(1));
    }

    function testInitializeRevertsZeroBeneficiary() public {
        vm.expectRevert(ZeroBeneficiary.selector);
        ownedBeneficiary.initialize(address(0), address(0));
    }

    function testInitialize() public {
        vm.expectEmit(true, true, false, true, address(ownedBeneficiary));
        emit Initialized(alice, bob);
        ownedBeneficiary.initialize(alice, bob);
        assertEq(ownedBeneficiary.owner(), alice);
        assertEq(ownedBeneficiary.beneficiary(), bob);
        assertEq(votingToken.delegates(address(ownedBeneficiary)), bob);
    }

    function testInitializeRevertsAlreadyInitialized() public {
        ownedBeneficiary.initialize(alice, bob);
        vm.expectRevert(AlreadyInitialized.selector);
        ownedBeneficiary.initialize(address(0), address(1));
    }

    function testDelegateRevertsNotBeneficiary() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                NotBeneficiary.selector,
                address(1),
                address(0)
            )
        );
        vm.prank(address(1));
        ownedBeneficiary.delegate(bob);
    }

    function testDelegateZero() public {
        ownedBeneficiary.initialize(alice, bob);
        vm.prank(bob);
        ownedBeneficiary.delegate(carol);
        assertEq(votingToken.delegates(address(ownedBeneficiary)), carol);
    }

    function testDelegateNonZero() public {
        ownedBeneficiary.initialize(alice, bob);
        vm.prank(bob);
        ownedBeneficiary.delegate(carol);
        votingToken.mint(address(ownedBeneficiary), 100);
        assertEq(votingToken.getVotes(carol), 100);
    }

    // fails because of onlyOwner
    function testFailRecall() public {
        ownedBeneficiary.recall(address(0));
    }

    function testRecallZero() public {
        vm.prank(address(0));
        ownedBeneficiary.recall(alice);
    }

    function testRecallNonZero() public {
        votingToken.mint(address(ownedBeneficiary), 100);
        vm.prank(address(0));
        ownedBeneficiary.recall(alice);
        assertEq(votingToken.balanceOf(alice), 100);
    }
}
