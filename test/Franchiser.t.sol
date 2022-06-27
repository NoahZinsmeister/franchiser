// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20, ERC20Permit, ERC20Votes} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Test} from "forge-std/Test.sol";
import {IFranchiserEvents} from "../src/interfaces/IFranchiserEvents.sol";
import {IFranchiserErrors} from "../src/interfaces/IFranchiserErrors.sol";
import {Franchiser} from "../src/Franchiser.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";

contract VotingTokenTest is ERC20Votes {
    constructor() ERC20("Test", "TEST") ERC20Permit("Test") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract FranchiserTest is Test, IFranchiserEvents, IFranchiserErrors {
    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

    VotingTokenTest private votingToken;
    Franchiser private franchiser;

    function setUp() public {
        votingToken = new VotingTokenTest();
        franchiser = new Franchiser(alice, IVotingToken(address(votingToken)));
    }

    function testSetUp() public {
        assertEq(address(franchiser.votingToken()), address(votingToken));
        assertEq(franchiser.owner(), alice);
        assertEq(franchiser.beneficiary(), address(0));
    }

    function testFailChangeBeneficiary() public {
        franchiser.changeBeneficiary(address(0));
    }

    function testChangeBeneficiary() public {
        vm.expectEmit(true, true, false, true, address(franchiser));
        emit BeneficiaryChanged(address(0), bob);
        vm.prank(alice);
        franchiser.changeBeneficiary(bob);
        assertEq(franchiser.beneficiary(), bob);
    }

    function testFailRecall() public {
        franchiser.recall(address(0));
    }

    function testRecallZero() public {
        vm.prank(alice);
        franchiser.recall(alice);
    }

    function testRecallNonZero() public {
        votingToken.mint(address(franchiser), 100);
        vm.prank(alice);
        franchiser.recall(alice);
        assertEq(votingToken.balanceOf(alice), 100);
    }

    function testDelegateReverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                NotBeneficiary.selector,
                address(1),
                address(0)
            )
        );
        vm.prank(address(1));
        franchiser.delegate(bob);
    }

    function testDelegateZero() public {
        vm.prank(alice);
        franchiser.changeBeneficiary(bob);
        vm.prank(bob);
        franchiser.delegate(bob);
        assertEq(votingToken.delegates(address(franchiser)), bob);
    }

    function testDelegateNonZero() public {
        vm.prank(alice);
        franchiser.changeBeneficiary(bob);
        vm.prank(bob);
        franchiser.delegate(bob);
        assertEq(votingToken.delegates(address(franchiser)), bob);
        votingToken.mint(address(franchiser), 100);
        assertEq(votingToken.getVotes(bob), 100);
    }
}
