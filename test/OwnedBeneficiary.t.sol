// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {ERC20, ERC20Permit, ERC20Votes} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {OwnedBeneficiary} from "../src/base/OwnedBeneficiary.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {IOwnedBeneficiaryErrors} from "../src/interfaces/OwnedBeneficiary/IOwnedBeneficiaryErrors.sol";
import {IOwnedBeneficiaryEvents} from "../src/interfaces/OwnedBeneficiary/IOwnedBeneficiaryEvents.sol";

contract VotingTokenConcrete is ERC20Votes {
    constructor() ERC20("Test", "TEST") ERC20Permit("Test") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract OwnedBeneficiaryConcrete is OwnedBeneficiary {
    constructor(IVotingToken votingToken) OwnedBeneficiary(votingToken) {}
}

contract OwnedBeneficiaryTest is
    Test,
    IOwnedBeneficiaryErrors,
    IOwnedBeneficiaryEvents
{
    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address private constant carol = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    VotingTokenConcrete private votingToken;
    OwnedBeneficiaryConcrete private ownedBeneficiary;

    function setUp() public {
        votingToken = new VotingTokenConcrete();
        vm.prank(alice);
        ownedBeneficiary = new OwnedBeneficiaryConcrete(
            IVotingToken(address(votingToken))
        );
    }

    function testSetUp() public {
        assertEq(ownedBeneficiary.owner(), alice);
        assertEq(ownedBeneficiary.beneficiary(), address(0));
    }

    function testFailInitialize() public {
        vm.prank(address(0));
        ownedBeneficiary.initialize(bob);
    }

    function testInitializeRevertsZeroBeneficiary() public {
        vm.expectRevert(ZeroBeneficiary.selector);
        vm.prank(alice);
        ownedBeneficiary.initialize(address(0));
    }

    function testInitialize() public {
        vm.expectEmit(true, false, false, true, address(ownedBeneficiary));
        emit Initialized(bob);
        vm.prank(alice);
        ownedBeneficiary.initialize(bob);
        assertEq(ownedBeneficiary.beneficiary(), bob);
        assertEq(votingToken.delegates(address(ownedBeneficiary)), bob);
    }

    function testInitializeRevertsAlreadyInitialized() public {
        vm.prank(alice);
        ownedBeneficiary.initialize(bob);
        vm.expectRevert(AlreadyInitialized.selector);
        vm.prank(alice);
        ownedBeneficiary.initialize(address(1));
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
        vm.prank(alice);
        ownedBeneficiary.initialize(bob);
        vm.prank(bob);
        ownedBeneficiary.delegate(carol);
        assertEq(votingToken.delegates(address(ownedBeneficiary)), carol);
    }

    function testDelegateNonZero() public {
        vm.prank(alice);
        ownedBeneficiary.initialize(bob);
        vm.prank(bob);
        ownedBeneficiary.delegate(carol);
        votingToken.mint(address(ownedBeneficiary), 100);
        assertEq(votingToken.getVotes(carol), 100);
    }

    function testFailRecall() public {
        ownedBeneficiary.recall(address(0));
    }

    function testRecallZero() public {
        vm.prank(alice);
        ownedBeneficiary.recall(alice);
    }

    function testRecallNonZero() public {
        votingToken.mint(address(ownedBeneficiary), 100);
        vm.prank(alice);
        ownedBeneficiary.recall(alice);
        assertEq(votingToken.balanceOf(alice), 100);
    }
}
