// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test, console2} from "forge-std/Test.sol";
import {IFranchiserFactoryErrors} from "../src/interfaces/FranchiserFactory/IFranchiserFactoryErrors.sol";
import {IFranchiserFactoryEvents} from "../src/interfaces/FranchiserFactory/IFranchiserFactoryEvents.sol";
import {VotingTokenConcrete} from "./VotingTokenConcrete.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {Franchiser} from "../src/Franchiser.sol";
import {Utils} from "./Utils.sol";

contract FranchiserFactoryTest is
    Test,
    IFranchiserFactoryErrors,
    IFranchiserFactoryEvents
{
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
            address(franchiserFactory.franchiserImplementation()),
            address(
                franchiserFactory
                    .franchiserImplementation()
                    .franchiserImplementation()
            )
        );
        assertEq(
            franchiserFactory.franchiserImplementation().owner(),
            address(0)
        );
        assertEq(
            franchiserFactory.franchiserImplementation().delegator(),
            address(0)
        );
        assertEq(
            franchiserFactory.franchiserImplementation().delegatee(),
            address(1)
        );
        assertEq(
            franchiserFactory.franchiserImplementation().maximumSubDelegatees(),
            0
        );
    }

    function testFundZero() public {
        Franchiser expectedFranchiser = franchiserFactory.getFranchiser(
            Utils.alice,
            Utils.bob
        );

        vm.expectEmit(true, true, false, true, address(franchiserFactory));
        emit NewFranchiser(Utils.alice, Utils.bob, expectedFranchiser);

        vm.prank(Utils.alice);
        Franchiser franchiser = franchiserFactory.fund(Utils.bob, 0);

        assertEq(address(expectedFranchiser), address(franchiser));
        assertEq(franchiser.owner(), address(franchiserFactory));
        assertEq(franchiser.delegatee(), Utils.bob);
        assertEq(votingToken.delegates(address(franchiser)), Utils.bob);
    }

    function testFundNonZeroRevertsTRANSFER_FROM_FAILED() public {
        vm.expectRevert(bytes("TRANSFER_FROM_FAILED"));
        franchiserFactory.fund(Utils.bob, 100);
    }

    function testFundNonZero() public {
        votingToken.mint(Utils.alice, 100);

        vm.startPrank(Utils.alice);
        votingToken.approve(address(franchiserFactory), 100);
        Franchiser franchiser = franchiserFactory.fund(Utils.bob, 100);
        vm.stopPrank();

        assertEq(votingToken.balanceOf(address(franchiser)), 100);
        assertEq(votingToken.getVotes(Utils.bob), 100);
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
        votingToken.mint(Utils.alice, 100);

        address[] memory delegatees = new address[](2);
        delegatees[0] = Utils.bob;
        delegatees[1] = Utils.carol;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50;
        amounts[1] = 50;

        vm.startPrank(Utils.alice);
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
        franchiserFactory.recall(Utils.bob, Utils.alice);
    }

    function testRecallNonZero() public {
        votingToken.mint(Utils.alice, 100);

        vm.startPrank(Utils.alice);
        votingToken.approve(address(franchiserFactory), 100);
        Franchiser franchiser = franchiserFactory.fund(Utils.bob, 100);
        franchiserFactory.recall(Utils.bob, Utils.alice);
        vm.stopPrank();

        assertEq(votingToken.balanceOf(address(franchiser)), 0);
        assertEq(votingToken.balanceOf(Utils.alice), 100);
        assertEq(votingToken.getVotes(Utils.bob), 0);
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
        votingToken.mint(Utils.alice, 100);

        address[] memory delegatees = new address[](2);
        delegatees[0] = Utils.bob;
        delegatees[1] = Utils.carol;

        address[] memory tos = new address[](2);
        tos[0] = Utils.alice;
        tos[1] = Utils.alice;

        vm.startPrank(Utils.alice);
        votingToken.approve(address(franchiserFactory), 100);
        franchiserFactory.fund(Utils.bob, 50);
        franchiserFactory.fund(Utils.carol, 50);
        franchiserFactory.recallMany(delegatees, tos);
        vm.stopPrank();

        assertEq(votingToken.balanceOf(Utils.alice), 100);
    }

    function testRecallGasWorstCase() public {
        Utils.nestMaximum(vm, votingToken, franchiserFactory);
        vm.prank(address(1));
        uint256 gasBefore = gasleft();
        franchiserFactory.recall(address(2), address(1));
        uint256 gasUsed = gasBefore - gasleft();
        unchecked {
            assertGt(gasUsed, 5 * 1e6);
            assertLt(gasUsed, 6 * 1e6);
            console2.log(gasUsed);
        }
        assertEq(votingToken.balanceOf(address(1)), 64);
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
            Utils.bob,
            100,
            deadline,
            v,
            r,
            s
        );

        assertEq(votingToken.balanceOf(address(franchiser)), 100);
        assertEq(votingToken.getVotes(Utils.bob), 100);
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
        delegatees[0] = Utils.bob;
        delegatees[1] = Utils.carol;

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
